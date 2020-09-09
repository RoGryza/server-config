// resource "hcloud_volume" "node_shared_storage" {
//   count    = var.node_count
//   name     = "node-shared-storage${count.index}"
//   location = hcloud_server.nodes[count.index].location
//   size     = 10
//   format   = "xfs"
// }

// resource "hcloud_volume_attachment" "node_shared_storage" {
//   count     = var.node_count
//   server_id = hcloud_server.nodes[count.index].id
//   volume_id = hcloud_volume.node_shared_storage[count.index].id
// }

// resource "null_resource" "setup_gluster" {
//   count = var.node_count
//   triggers = {
//     server : hcloud_volume_attachment.node_shared_storage[count.index].server_id,
//     volume : hcloud_volume.node_shared_storage[count.index].linux_device,
//   }

//   connection {
//     host        = hcloud_server.nodes[count.index].ipv4_address
//     port        = random_integer.ssh_port.result
//     user        = "terraform"
//     private_key = tls_private_key.terraform.private_key_pem
//   }

//   provisioner "remote-exec" {
//     inline = [
//       "sudo mkdir -p /export",
//       "echo '${hcloud_volume.node_shared_storage[count.index].linux_device} /export xfs defaults 1 2' | sudo tee -a /etc/fstab",
//       "sudo mount -a && sudo mount",
//       "sudo mkdir -p /export/brick",
//       "until $(which gluster >/dev/null 2>&1); do sleep 1; done",
//       "until $(sudo systemctl enable --now glusterd >/dev/null 2>&1); do sleep 1; done",
//     ]
//   }
// }

// resource "null_resource" "gluster_probe_first" {
//   depends_on = [null_resource.setup_gluster]
//   triggers = {
//     gluster : null_resource.setup_gluster.0.id,
//     network : hcloud_server_network.private.0.ip,
//   }

//   connection {
//     type        = "ssh"
//     host        = hcloud_server.nodes.0.ipv4_address
//     port        = random_integer.ssh_port.result
//     user        = "terraform"
//     private_key = tls_private_key.terraform.private_key_pem
//   }

//   provisioner "remote-exec" {
//     inline = [
//       for i in range(1, var.node_count) :
//       "sudo gluster peer probe '${hcloud_server_network.private[i].ip}'"
//     ]
//   }
// }

// resource "null_resource" "gluster_probe_rest" {
//   count      = var.node_count - 1
//   depends_on = [null_resource.gluster_probe_first]
//   triggers = {
//     gluster : null_resource.gluster_probe_first.id,
//     network : hcloud_server_network.private.0.ip,
//   }

//   connection {
//     host        = hcloud_server.nodes[count.index + 1].ipv4_address
//     port        = random_integer.ssh_port.result
//     user        = "terraform"
//     private_key = tls_private_key.terraform.private_key_pem
//   }

//   provisioner "remote-exec" {
//     inline = ["sudo gluster peer probe '${hcloud_server_network.private.0.ip}'"]
//   }
// }

// resource "null_resource" "gluster_shared_volume" {
//   depends_on = [null_resource.gluster_probe_rest]
//   triggers = {
//     gluster : join(", ", null_resource.gluster_probe_rest.*.id)
//   }

//   connection {
//     type        = "ssh"
//     host        = hcloud_server.nodes.0.ipv4_address
//     port        = random_integer.ssh_port.result
//     user        = "terraform"
//     private_key = tls_private_key.terraform.private_key_pem
//   }

//   provisioner "remote-exec" {
//     inline = [
//       join(" ", concat(
//         ["sudo gluster volume create gv0 replica ${var.node_count}"],
//         [for net in hcloud_server_network.private : "${net.ip}:/export/brick"]
//       )),
//       "sudo gluster volume start gv0",
//     ]
//   }
// }

// resource "null_resource" "gluster_shared_volume_mount" {
//   count      = var.node_count
//   depends_on = [null_resource.gluster_shared_volume]
//   triggers = {
//     gluster : null_resource.gluster_shared_volume.id
//   }

//   connection {
//     type        = "ssh"
//     host        = hcloud_server.nodes[count.index].ipv4_address
//     port        = random_integer.ssh_port.result
//     user        = "terraform"
//     private_key = tls_private_key.terraform.private_key_pem
//   }

//   provisioner "remote-exec" {
//     inline = [
//       "sudo mkdir -p /mnt/shared",
//       "echo '${hcloud_server.nodes[count.index].name}:/gv0 /mnt/shared glusterfs defaults,_netdev,x-systemd.requires=gluster.service,x-systemd.automount 0 0' | sudo tee -a /etc/fstab",
//       "sudo mount -a && sudo mount",
//     ]
//   }
// }
