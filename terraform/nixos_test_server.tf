# output "nixos_test_ip" {
#   value = digitalocean_droplet.nixos_test.ipv4_address
# }

# resource "random_password" "nixos_test_admin" {
#   length  = 12
#   special = false
# }

# resource "random_integer" "nixos_test_ssh_port" {
#   min = 1
#   max = 65535
# }

# data "template_cloudinit_config" "nixos_test_config" {
#   base64_encode = false
#   gzip          = false
#   part {
#     content_type = "text/cloud-config"
#     content = yamlencode({
#       write_files : [{
#         path        = "/etc/nixos/host.nix"
#         permissions = "0644"
#         content     = <<EOF
#           {pkgs, ...}:
#           {
#             environment.systemPackages = with pkgs; [ vim ];
#           }
#           EOF
#       }],
#       runcmd : [
#         "curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | PROVIDER=digitalocean NIXOS_IMPORT=./host.nix NIX_CHANNEL=nixos-22.05 bash 2>&1 | tee /tmp/infect.log"
#       ]
#     })
#   }
# }

# resource "digitalocean_droplet" "nixos_test" {
#   name      = "nixos-test"
#   image     = "ubuntu-22-10-x64"
#   size      = "s-1vcpu-512mb-10gb"
#   region    = "nyc1"
#   ssh_keys  = [digitalocean_ssh_key.admin.fingerprint]
#   user_data = data.template_cloudinit_config.nixos_test_config.rendered
#   tags      = ["nixos_test"]
# }
