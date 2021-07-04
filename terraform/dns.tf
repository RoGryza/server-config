provider "cloudflare" {
}

# TODO manage zone settings
resource "cloudflare_zone" "rogryza_me" {
  zone = "rogryza.me"
}

resource "cloudflare_record" "rogryza_me_root" {
  zone_id = cloudflare_zone.rogryza_me.id
  name    = "@"
  type    = "A"
  value   = digitalocean_droplet.default.ipv4_address
  # TODO should this be true?
  proxied = false
}

# TODO maybe we could manage this from docker:
# https://github.com/tiredofit/docker-traefik-cloudflare-companion
resource "cloudflare_record" "rogryza_me_wildcard" {
  zone_id = cloudflare_zone.rogryza_me.id
  name    = "*"
  type    = "CNAME"
  value   = cloudflare_zone.rogryza_me.zone
  proxied = false
}
