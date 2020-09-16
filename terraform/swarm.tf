resource "null_resource" "swarm_init" {
  triggers = {
    server : hcloud_server.managers.0.id,
    server_ip : hcloud_server_network.private.0.ip,
    connection_ip : hcloud_server.managers.0.ipv4_address,
    connection_port : random_integer.ssh_port.result,
    connection_key : tls_private_key.terraform.private_key_pem,
  }

  connection {
    type        = "ssh"
    host        = self.triggers.connection_ip
    port        = self.triggers.connection_port
    user        = "terraform"
    private_key = self.triggers.connection_key
  }

  provisioner "remote-exec" {
    inline = [
      "until $(systemctl is-active docker.socket >/dev/null 2>&1); do sleep 1; done",
      "docker swarm init --listen-addr ${self.triggers.server_ip} --advertise-addr ${self.triggers.server_ip} >> ~/provision.log 2>&1",
    ]
  }

  provisioner "remote-exec" {
      when = destroy
      inline = ["docker swarm leave --force"]
  }
}

resource "null_resource" "swarm_join_manager" {
  depends_on = [null_resource.swarm_init, hcloud_server_network.private]
  count      = var.manager_count - 1
  triggers = {
    swarm_init : null_resource.swarm_init.id,
    server: hcloud_server.managers[count.index + 1].id,
    server_name: hcloud_server.managers[count.index + 1].name, 
    server_ip : hcloud_server_network.private[count.index + 1].ip,
    master_ip : hcloud_server_network.private.0.ip,
    connection_ip : hcloud_server.managers[count.index + 1].ipv4_address,
    connection_port : random_integer.ssh_port.result,
    connection_key : tls_private_key.terraform.private_key_pem,
  }

  connection {
    type        = "ssh"
    host        = self.triggers.connection_ip
    port        = self.triggers.connection_port
    user        = "terraform"
    private_key = self.triggers.connection_key
  }

  provisioner "remote-exec" {
    inline = [
      "until $(systemctl is-active docker.socket >/dev/null 2>&1); do sleep 1; done",
      "TOKEN=$(ssh -o StrictHostKeyChecking=no -p ${self.triggers.connection_port} ${self.triggers.master_ip} 'docker swarm join-token -q manager')",
      "docker swarm join --token $TOKEN ${self.triggers.master_ip}:2377 >> ~/provision.log 2>&1",
    ]
  }

  provisioner "remote-exec" {
      when = destroy
      inline = [
          "docker node demote ${self.triggers.server_name}",
          "docker swarm leave",
          <<-EOF
            ssh -o StrictHostKeyChecking=no -p ${self.triggers.connection_port} ${self.triggers.master_ip} \
                'until [ $(docker node inspect ${self.triggers.server_name} --format "{{.Status.State}}") == "down" ]; do sleep 1; done; docker node rm ${self.triggers.server_name}'
          EOF
        ]
  }
}