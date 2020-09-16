variable manager_count {
  default = 3
}

variable admin_username {
  default = "rogryza"
}

output ips {
  value = { for server in hcloud_server.managers : server.name => server.ipv4_address }
}

output ssh_port {
  value = random_integer.ssh_port.result
}

output admin_password {
  value = random_password.admin.result
  sensitive = true
}

provider "hcloud" {
}

data "hcloud_locations" "loc" {
}

data "hcloud_image" "default" {
  with_selector = "me.rogryza.name=rogryza"
  most_recent = true
}

resource "random_password" "admin" {
  length  = 12
  special = false
}

resource "random_integer" "ssh_port" {
  min = 1
  max = 65535
}

resource "tls_private_key" "terraform" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "tls_private_key" "node_terraform" {
  count = var.manager_count
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "hcloud_network" "private" {
  name     = "private"
  ip_range = "10.0.0.0/24"
}

resource "hcloud_network_subnet" "private" {
  type         = "server"
  network_id   = hcloud_network.private.id
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/24"
}

resource "hcloud_ssh_key" "admin" {
  name       = "admin"
  public_key = file("files/id_rsa.pub")
}

data "template_cloudinit_config" "config" {
  part {
    content_type = "text/cloud-config"
    content = yamlencode({
      package_update : true,
      package_upgrade : true,
      packages : [
        "docker.io",
        "apt-transport-https",
        "ca-certificates",
        "glusterfs-server",
      ]
      users : [
        {
          name : var.admin_username,
          plain_text_passwd : random_password.admin.result,
          lock_passwd : false,
          groups : ["docker"],
          ssh_authorized_keys : [hcloud_ssh_key.admin.public_key],
          sudo : ["ALL=(ALL) ALL"],
          shell : "/bin/bash",
        },
        {
          name : "terraform",
          lock_passwd : false,
          groups : ["docker"],
          ssh_authorized_keys : concat([tls_private_key.terraform.public_key_openssh], [
            for k in tls_private_key.node_terraform : k.public_key_openssh
          ]),
          sudo : ["ALL=(ALL) NOPASSWD: ALL"],
          shell : "/bin/bash",
        }
      ],
      write_files : [{
        path : "/etc/ssh/sshd_config",
        content : templatefile("files/sshd_config", { port : random_integer.ssh_port.result }),
      }]
    })
  }
}