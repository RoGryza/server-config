variable node_count {
  default = 3
}

variable admin_username {
  default = "rogryza"
}

output ips {
  value = { for server in hcloud_server.nodes : server.name => server.ipv4_address }
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
  rsa_bits  = 2048
}

resource "tls_private_key" "node_terraform" {
  count     = var.node_count
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "hcloud_network" "private" {
  name     = "private"
  ip_range = "10.0.1.0/24"
}

resource "hcloud_network_subnet" "private" {
  network_id   = hcloud_network.private.id
  network_zone = "eu-central"
  type         = "cloud"
  ip_range     = hcloud_network.private.ip_range
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
          groups : ["docker"],
          ssh_authorized_keys : concat([tls_private_key.terraform.public_key_openssh], [
            for k in tls_private_key.node_terraform : k.public_key_openssh
          ]),
          sudo : ["ALL=(ALL) NOPASSWD: ALL"],
          shell : "/bin/bash"
        }
      ],
      write_files : [{
        path : "/etc/ssh/sshd_config",
        content : templatefile("files/sshd_config", { port : random_integer.ssh_port.result }),
      }]
    })
  }
}

resource "hcloud_ssh_key" "admin" {
  name       = "default"
  public_key = file("files/id_rsa.pub")
}

resource "hcloud_server" "nodes" {
  count       = var.node_count
  name        = "node${count.index}"
  image       = data.hcloud_image.default.id
  server_type = "cx11"
  location    = element(data.hcloud_locations.loc.names, count.index)
  ssh_keys    = [hcloud_ssh_key.admin.id]
  user_data   = data.template_cloudinit_config.config.rendered

  connection {
    type        = "ssh"
    host        = self.ipv4_address
    port        = random_integer.ssh_port.result
    user        = "terraform"
    private_key = tls_private_key.terraform.private_key_pem
  }

  // SSH key set here because cloud-config sets /home/terraform to root:root
  provisioner "file" {
    destination = "/home/terraform/.ssh/id_rsa"
    content     = tls_private_key.node_terraform[count.index].private_key_pem
  }

  provisioner "file" {
    destination = "/home/terraform/.ssh/id_rsa.pub"
    content     = tls_private_key.node_terraform[count.index].public_key_openssh
  }

  provisioner "remote-exec" {
    inline = [
      "chown -R terraform:terraform /home/terraform/.ssh",
      "chmod 0600 /home/terraform/.ssh/id_rsa",
    ]
  }
}

resource "hcloud_server_network" "private" {
  count     = var.node_count
  server_id = hcloud_server.nodes[count.index].id
  subnet_id = hcloud_network_subnet.private.id
}

resource "null_resource" "swarm_token" {
  triggers = {
    server : hcloud_server.nodes.0.id,
    network : hcloud_server_network.private.0.ip,
  }

  connection {
    type        = "ssh"
    host        = hcloud_server.nodes.0.ipv4_address
    port        = random_integer.ssh_port.result
    user        = "terraform"
    private_key = tls_private_key.terraform.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm init --listen-addr ${hcloud_server_network.private.0.ip} --advertise-addr ${hcloud_server_network.private.0.ip} >> ~/provision.log 2>&1",
    ]
  }
}

resource "null_resource" "swarm_join" {
  depends_on = [null_resource.swarm_token, hcloud_server_network.private]
  count      = var.node_count - 1
  triggers = {
    first_manager : hcloud_server.nodes.0.id,
    server : hcloud_server.nodes[count.index + 1].id,
    network : hcloud_server_network.private.0.ip,
    server_ip : hcloud_server_network.private[count.index + 1].ip,
  }

  connection {
    host        = hcloud_server.nodes[count.index + 1].ipv4_address
    port        = random_integer.ssh_port.result
    user        = "terraform"
    private_key = tls_private_key.terraform.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "TOKEN=$(ssh -o StrictHostKeyChecking=no -p ${random_integer.ssh_port.result} ${hcloud_server_network.private.0.ip} 'docker swarm join-token -q manager')",
      "docker swarm join --token $TOKEN ${hcloud_server_network.private.0.ip}:2377 >> ~/provision.log 2>&1",
    ]
  }
}

resource "hcloud_volume" "node_shared_storage" {
  count    = var.node_count
  name     = "node-shared-storage${count.index}"
  location = hcloud_server.nodes[count.index].location
  size     = 10
  format   = "xfs"
}

resource "hcloud_volume_attachment" "node_shared_storage" {
  count     = var.node_count
  server_id = hcloud_server.nodes[count.index].id
  volume_id = hcloud_volume.node_shared_storage[count.index].id
}

resource "null_resource" "setup_gluster" {
  count = var.node_count
  triggers = {
    server : hcloud_volume_attachment.node_shared_storage[count.index].server_id,
    volume : hcloud_volume.node_shared_storage[count.index].linux_device,
  }

  connection {
    host        = hcloud_server.nodes[count.index].ipv4_address
    port        = random_integer.ssh_port.result
    user        = "terraform"
    private_key = tls_private_key.terraform.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /export",
      "echo '${hcloud_volume.node_shared_storage[count.index].linux_device} /export xfs defaults 1 2' | sudo tee -a /etc/fstab",
      "sudo mount -a && sudo mount",
      "sudo mkdir -p /export/brick",
      "until $(sudo systemctl enable --now glusterd >/dev/null 2>&1); do sleep 1; done",
    ]
  }
}

resource "null_resource" "gluster_probe_first" {
  depends_on = [null_resource.setup_gluster]
  triggers = {
    gluster : null_resource.setup_gluster.0.id,
    network : hcloud_server_network.private.0.ip,
  }

  connection {
    type        = "ssh"
    host        = hcloud_server.nodes.0.ipv4_address
    port        = random_integer.ssh_port.result
    user        = "terraform"
    private_key = tls_private_key.terraform.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      for i in range(1, var.node_count) :
      "sudo gluster peer probe '${hcloud_server_network.private[i].ip}'"
    ]
  }
}

resource "null_resource" "gluster_probe_rest" {
  count      = var.node_count - 1
  depends_on = [null_resource.gluster_probe_first]
  triggers = {
    gluster : null_resource.gluster_probe_first.id,
    network : hcloud_server_network.private.0.ip,
  }

  connection {
    host        = hcloud_server.nodes[count.index + 1].ipv4_address
    port        = random_integer.ssh_port.result
    user        = "terraform"
    private_key = tls_private_key.terraform.private_key_pem
  }

  provisioner "remote-exec" {
    inline = ["sudo gluster peer probe '${hcloud_server_network.private.0.ip}'"]
  }
}

resource "null_resource" "gluster_shared_volume" {
  depends_on = [null_resource.gluster_probe_rest]
  triggers = {
    gluster : join(", ", null_resource.gluster_probe_rest.*.id)
  }

  connection {
    type        = "ssh"
    host        = hcloud_server.nodes.0.ipv4_address
    port        = random_integer.ssh_port.result
    user        = "terraform"
    private_key = tls_private_key.terraform.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      join(" ", concat(
        ["sudo gluster volume create gv0 replica ${var.node_count}"],
        [for net in hcloud_server_network.private : "${net.ip}:/export/brick"]
      )),
      "sudo gluster volume start gv0",
    ]
  }
}

resource "null_resource" "gluster_shared_volume_mount" {
  count      = var.node_count
  depends_on = [null_resource.gluster_shared_volume]
  triggers = {
    gluster : null_resource.gluster_shared_volume.id
  }

  connection {
    type        = "ssh"
    host        = hcloud_server.nodes[count.index].ipv4_address
    port        = random_integer.ssh_port.result
    user        = "terraform"
    private_key = tls_private_key.terraform.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /mnt/shared",
      "echo '${hcloud_server.nodes[count.index].name}:/gv0 /mnt/shared glusterfs defaults,_netdev,x-systemd.requires=gluster.service,x-systemd.automount 0 0' | sudo tee -a /etc/fstab",
      "sudo mount -a && sudo mount",
    ]
  }
}
