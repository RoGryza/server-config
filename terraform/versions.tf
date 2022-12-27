terraform {
  backend "s3" {
    # Make it work with backblaze
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true

    # TODO get bucket data from bootstrap output if possible
    bucket   = "me-rogryza-tf-backend"
    region   = "us-west-004"
    key      = "tfstate"
    endpoint = "https://s3.us-west-004.backblazeb2.com"
  }

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
