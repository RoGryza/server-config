variable "hc_token" {
  type      = string
  sensitive = true
}

variable "name" {
  type    = string
  default = "rogryza"
}

source "hcloud" "default" {
  image_filter {
    most_recent   = true
    with_selector = ["me.rogryza.name==${var.name},me.rogryza.os==ubuntu-20.04"]
  }
  location    = "nbg1"
  server_type = "cx11"
  snapshot_labels = {
    "me.rogryza.name" = var.name
    "me.rogryza.os" = "ubuntu-20.04"
  }
  snapshot_name = "${var.name}-ubuntu-${md5(file("main.pkr.hcl"))}"
  ssh_username  = "root"
  token         = var.hc_token
}

build {
  sources = ["source.hcloud.default"]

  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
      "apt-get install -y ansible apt-transport-https docker ca-certificates",
    ]
  }

  provisioner "ansible-local" {
    playbook_file = "./playbook.yml"
  }
}
