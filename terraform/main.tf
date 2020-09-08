variable servers_count {
  default = 3
}

variable admin_username {
  default = "rogryza"
}

output ips {
  value = { for server in hcloud_server.control_planes : server.name => server.ipv4_address }
}

output ssh_port {
  value = random_integer.ssh_port.result
}

output admin_password {
  value = random_password.admin.result
}

provider "hcloud" {
}

data "hcloud_locations" "loc" {
}

resource "hcloud_ssh_key" "admin" {
  name       = "default"
  public_key = file("files/id_rsa.pub")
}

data "hcloud_image" "default" {
  with_selector = "me.rogryza.name==rogryza"
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

resource "hcloud_network" "k3s" {
  name     = "private"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "k3s_nodes" {
  type         = "server"
  network_id   = hcloud_network.k3s.id
  network_zone = "eu-central"
  ip_range     = "10.254.1.0/24"
}

data "template_cloudinit_config" "config" {
  part {
    content_type = "text/cloud-config"
    content = yamlencode({
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
          ssh_authorized_keys : tls_private_key.terraform.public_key_openssh,
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