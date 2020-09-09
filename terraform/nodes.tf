resource "hcloud_server" "managers" {
  count       = var.manager_count
  name        = "manager-${count.index}"
  image = data.hcloud_image.default.id
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
  count     = var.manager_count
  server_id = hcloud_server.managers[count.index].id
  subnet_id = hcloud_network_subnet.private.id
}