variable "admin_username" {
  default = "rogryza"
}

output "ssh_port" {
  value = random_integer.ssh_port.result
}

output "ip" {
  value = hcloud_server.default.ipv4_address
}

// TODO this is probably bad practice
output "admin_password" {
  value     = random_password.admin.result
  sensitive = true
}

provider "hcloud" {
}

data "hcloud_locations" "loc" {
}

data "hcloud_image" "default" {
  with_selector = "me.rogryza.name=rogryza"
  most_recent   = true
}

resource "random_password" "admin" {
  length  = 12
  special = false
}

resource "random_integer" "ssh_port" {
  min = 1
  max = 65535
}

resource "hcloud_ssh_key" "admin" {
  name       = "admin"
  public_key = file("files/id_rsa.pub")
}

data "template_cloudinit_config" "config" {
  base64_encode = false
  gzip          = false
  part {
    content_type = "text/cloud-config"
    content = yamlencode({
      ssh_pwauth : false,
      users : [
        {
          name : var.admin_username,
          plain_text_passwd : random_password.admin.result,
          lock_passwd : false,
          ssh_authorized_keys : [hcloud_ssh_key.admin.public_key],
          sudo : ["ALL=(ALL) ALL"],
          shell : "/bin/bash",
        }
      ],
      write_files : [{
        path : "/etc/ssh/sshd_config",
        content : templatefile("files/sshd_config", { port : random_integer.ssh_port.result }),
      }],
      runcmd : [
        // Deativate short moduli https://infosec.mozilla.org/guidelines/openssh#modern-openssh-67
        "awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.tmp",
        "mv /etc/ssh/moduli.tmp /etc/ssh/moduli",
      ]
    })
  }
}

resource "hcloud_server" "default" {
  name        = "rogryza.me"
  image       = data.hcloud_image.default.id
  server_type = "cpx11"
  location    = data.hcloud_locations.loc.names[0]
  ssh_keys    = [hcloud_ssh_key.admin.id]
  user_data   = data.template_cloudinit_config.config.rendered
}
