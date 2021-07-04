provider "cloudflare" {
}

resource "cloudflare_zone" "rogryza_me" {
  zone = "rogryza.me"
}

resource "cloudflare_record" "rogryza_me" {
  zone_id = cloudflare_zone.rogryza_me.id
  name    = "@"
  type    = "A"
  value   = digitalocean_droplet.default.ipv4_address
  proxied = true
}
