module "k3s" {
    source = "git::https://github.com/xunleii/terraform-module-k3s?ref=v2.1.0"

    depends_on = [hcloud_server.control_planes]
    name = "rogryza"
    cidr = {
        pods     = "10.42.0.0/16"
        services = "10.43.0.0/16"
    }
    drain_timeout = "30s"
    managed_fields = ["label", "taint"]

    global_flags = [
        "--flannel-iface ens10",
        "--kubelet-arg cloud-provider=external",
        "--write-kubeconfig-mode=644",
    ]

    servers = {
        for i in range(length(hcloud_server.control_planes)) :
        hcloud_server.control_planes[i].name => {
            ip = hcloud_server_network.control_planes[i].ip
            connection = {
                user = "terraform"
                host = hcloud_server.control_planes[i].ipv4_address
                port = random_integer.ssh_port.result
                private_key = tls_private_key.terraform.private_key_pem
            }
            flags = ["--disable-cloud-controller"]
        }
    }
}