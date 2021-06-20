packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/digitalocean"
    }
  }
}

variable "name" {
  type    = string
  default = "rogryza"
}

source "digitalocean" "default" {
  image = "ubuntu-20-04-x64"
  region = "lon1"
  size = "s-1vcpu-1gb"
  ssh_username  = "root"
  snapshot_name = "${var.name}-ubuntu-${md5(file("main.pkr.hcl"))}"
  tags = ["me_rogryza"]
}

build {
  sources = ["source.digitalocean.default"]

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
      // TODO get rid of ansible?
      "apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
      "apt-add-repository ppa:ansible/ansible",
      "apt-get update",
      "apt-get install -y ansible",
    ]
  }

  provisioner "ansible-local" {
    playbook_file = "./playbook.yml"
  }
}

# TODO delete old images
