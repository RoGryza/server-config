terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "2.23.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    b2 = {
      source = "Backblaze/b2"
    }
  }
  required_version = ">= 1.0"
}
