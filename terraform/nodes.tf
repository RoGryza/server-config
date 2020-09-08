
resource "hcloud_server" "control_planes" {
  count       = var.servers_count
  name        = "control-plane-${count.index}"
  image       = data.hcloud_image.default.id
  server_type = "cx11"
  location    = element(data.hcloud_locations.loc.names, count.index)
  ssh_keys    = [hcloud_ssh_key.admin.id]
  user_data   = data.template_cloudinit_config.config.rendered
}

resource "hcloud_server_network" "control_planes" {
  count       = var.servers_count
  server_id = hcloud_server.control_planes[count.index].id
  subnet_id = hcloud_network_subnet.k3s_nodes.id
  ip        = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 1 + count.index)
}