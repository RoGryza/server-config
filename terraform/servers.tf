output "ssh_port" {
  value = random_integer.ssh_port.result
}

output "ip" {
  value = digitalocean_droplet.default.ipv4_address
}

// TODO this is probably bad practice
output "admin_password" {
  value     = random_password.admin.result
  sensitive = true
}

resource "random_password" "admin" {
  length  = 12
  special = false
}

resource "random_integer" "ssh_port" {
  min = 1
  max = 65535
}

resource "digitalocean_ssh_key" "admin" {
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
          name : "rogryza",
          plain_text_passwd : random_password.admin.result,
          lock_passwd : false,
          ssh_authorized_keys : [digitalocean_ssh_key.admin.public_key],
          groups : "docker",
          sudo : ["ALL=(ALL) ALL"],
          shell : "/bin/bash",
        }
      ],
      write_files : [{
        path : "/etc/ssh/sshd_config",
        // TODO change sftp to /usr/lib/ instead
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

data "digitalocean_images" "custom" {
  filter {
    key      = "name"
    match_by = "re"
    values   = ["^rogryza-ubuntu-[a-f0-9]{32}"]
  }
  sort {
    key       = "created"
    direction = "desc"
  }
}

resource "digitalocean_droplet" "default" {
  name      = "rogryza.me"
  image     = data.digitalocean_images.custom.images[0].id
  size      = "s-1vcpu-1gb"
  region    = "lon1"
  ssh_keys  = [digitalocean_ssh_key.admin.fingerprint]
  user_data = data.template_cloudinit_config.config.rendered
  tags      = ["me_rogryza"]
}
