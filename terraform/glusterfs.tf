resource "hcloud_volume" "manager_brick" {
  count    = var.manager_count
  name     = "node-shared-storage-${count.index}"
  location = hcloud_server.managers[count.index].location
  size     = 10
  format   = "xfs"
}

resource "hcloud_volume_attachment" "manager_brick" {
  count     = var.manager_count
  server_id = hcloud_server.managers[count.index].id
  volume_id = hcloud_volume.manager_brick[count.index].id
}

resource "null_resource" "manager_mount_brick" {
  count = var.manager_count
  triggers = {
    server : hcloud_volume_attachment.manager_brick[count.index].server_id,
    linux_device : hcloud_volume.manager_brick[count.index].linux_device,
    connection_host : hcloud_server.managers[count.index].ipv4_address,
    connection_port : random_integer.ssh_port.result,
    connection_private_key : tls_private_key.terraform.private_key_pem,
  }

  connection {
    host        = self.triggers.connection_host
    port        = self.triggers.connection_port
    user        = "terraform"
    private_key = self.triggers.connection_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /gluster",
      "echo '${self.triggers.linux_device} /gluster xfs defaults 1 2' | sudo tee -a /etc/fstab",
      "sudo mount -a && sudo mount",
    ]
  }

  provisioner "remote-exec" {
      when = destroy
      inline = [
          "sudo umount /gluster",
          "sudo sed -i '/^${replace(self.triggers.linux_device, "/", "\\/")}/d' /etc/fstab",
          "sudo rm -rf /gluster",
      ]
  }
}

resource "null_resource" "gluster_probe_first" {
  triggers = {
    brick : null_resource.manager_mount_brick.0.id,
    network : join(", ", hcloud_server_network.private.*.ip),
  }

  connection {
    host        = hcloud_server.managers.0.ipv4_address
    port        = random_integer.ssh_port.result
    user        = "terraform"
    private_key = tls_private_key.terraform.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      for i in range(1, var.manager_count) :
      "sudo gluster peer probe '${hcloud_server_network.private[i].ip}'"
    ]
  }
}

resource "null_resource" "gluster_probe_rest" {
  count      = var.manager_count - 1
  triggers = {
    gluster : null_resource.gluster_probe_first.id,
  }

  connection {
    host        = hcloud_server.managers[count.index + 1].ipv4_address
    port        = random_integer.ssh_port.result
    user        = "terraform"
    private_key = tls_private_key.terraform.private_key_pem
  }

  provisioner "remote-exec" {
    inline = ["sudo gluster peer probe '${hcloud_server_network.private.0.ip}'"]
  }
}

resource "null_resource" "gluster_detach" {
    count = var.manager_count - 1
    depends_on = [null_resource.gluster_probe_rest]
    triggers = {
        host_ip : hcloud_server_network.private[count.index + 1].ip,
        connection_host : hcloud_server.managers.0.ipv4_address,
        connection_port : random_integer.ssh_port.result,
        connection_private_key : tls_private_key.terraform.private_key_pem,
    }
    lifecycle {
        ignore_changes = [triggers]
    }

  connection {
    host        = self.triggers.connection_host
    port        = self.triggers.connection_port
    user        = "terraform"
    private_key = self.triggers.connection_private_key
  }

  // TODO this doesn't work, peering should be handled better
  provisioner "remote-exec" {
      when = destroy
      inline = ["sudo gluster peer detach ${self.triggers.host_ip}"]
  }
}

resource "null_resource" "gluster_volume_gv0" {
  triggers = {
    gluster : join(", ", null_resource.gluster_probe_rest.*.id),
    connection_host : hcloud_server.managers.0.ipv4_address,
    connection_port : random_integer.ssh_port.result,
    connection_private_key : tls_private_key.terraform.private_key_pem,
  }

  connection {
    host        = self.triggers.connection_host
    port        = self.triggers.connection_port
    user        = "terraform"
    private_key = self.triggers.connection_private_key
  }

  provisioner "remote-exec" {
    inline = [
      join(" ", concat(
        ["sudo gluster volume create gv0 replica ${var.manager_count}"],
        [for net in hcloud_server_network.private : "${net.ip}:/gluster/brick"]
      )),
      "sudo gluster volume start gv0",
    ]
  }

  provisioner "remote-exec" {
      when = destroy
      inline = [
          "sudo gluster volume stop gv0",
          "sudo gluster volume delete gv0",
      ]
  }
}

resource "null_resource" "mount_export" {
  count      = var.manager_count
  triggers = {
    gluster : null_resource.gluster_volume_gv0.id,
    connection_host : hcloud_server.managers[count.index].ipv4_address,
    connection_port : random_integer.ssh_port.result,
    connection_private_key : tls_private_key.terraform.private_key_pem,
  }

  connection {
    host        = self.triggers.connection_host
    port        = self.triggers.connection_port
    user        = "terraform"
    private_key = self.triggers.connection_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /export",
      "echo '${self.triggers.connection_host}:/gv0 /export glusterfs defaults,_netdev,x-systemd.requires=gluster.service,x-systemd.automount 0 0' | sudo tee -a /etc/fstab",
      "sudo mount -a && sudo mount",
    ]
  }

  provisioner "remote-exec" {
      when = destroy
      inline = [
          "sudo umount /export",
          "sudo sed -i '/^${replace(self.triggers.connection_host, "/", "\\/")}/d' /etc/fstab",
          "sudo rm -rf /export",
      ]
  }
}
