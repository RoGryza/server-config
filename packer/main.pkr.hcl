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
      "apt-get install -y apt-transport-https docker ca-certificates mosh unattended-upgrades ntp",
      "add-apt-repository -y ppa:gluster/glusterfs-8",
      "apt-get update",
      "apt-get install -y glusterfs-server",
      "systemctl enable glusterd --now",
    ]
  }
  provisioner "file" {
    destination = "/etc/apt/apt.conf.d/20auto-upgrades"
    source      = "20auto-upgrades"
  }

  provisioner "file" {
    destination = "/etc/ntp.conf"
    source      = "ntp.conf"
  }
}
