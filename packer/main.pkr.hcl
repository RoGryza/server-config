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
    with_selector = ["me.rogryza.name==${var.name}"]
  }
  location    = "nbg1"
  server_type = "cx11"
  snapshot_labels = {
    "me.rogryza.name" = var.name
  }
  snapshot_name = "${var.name}-${md5(file("main.pkr.hcl"))}"
  ssh_username  = "root"
  token         = var.hc_token
}

build {
  sources = ["source.hcloud.default"]

  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
      "apt-get install -y docker.io apt-transport-https ca-certificates unattended-upgrades glusterfs-server",
    ]
  }
  provisioner "file" {
    destination = "/etc/apt/apt.conf.d/20auto-upgrades"
    source      = "20auto-upgrades"
  }
}
