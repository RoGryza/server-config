variable "hc_token" {
  type      = string
  sensitive = true
}

variable "name" {
  type    = string
  default = "rogryza"
}

source "hcloud" "default" {
  // image_filter {
  //   most_recent   = true
  //   with_selector = ["me.rogryza.name==${var.name}"]
  // }
  image = "centos-8"
  location    = "nbg1"
  server_type = "cx11"
  snapshot_labels = {
    "me.rogryza.name" = var.name
    "me.rogryza.os" = "centos-8"
  }
  snapshot_name = "${var.name}-centos-${md5(file("main.pkr.hcl"))}"
  ssh_username  = "root"
  token         = var.hc_token
}

build {
  sources = ["source.hcloud.default"]

  provisioner "shell" {
    inline = [
      "dnf -y update",
      "dnf -y install epel-release",
      "dnf -y install ansible",
    ]
  }

  provisioner "ansible-local" {
    playbook_file = "./playbook.yml"
  }
}
