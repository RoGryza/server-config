terraform {
  required_providers {
    hcloud = {
      source = "terraform-providers/hcloud"
    }
    hetznerdns = {
      source = "timohirt/hetznerdns"
      version = "1.0.6"
    }
  }
  required_version = ">= 0.13"
}
