terraform {
  required_providers {
    hcloud = {
      source = "terraform-providers/hcloud"
    }
    hetznerdns = {
      source = "timohirt/hetznerdns"
      version = "1.0.6"
    }
    ansible = {
      source = "nbering/ansible"
      version = "1.0.4"
    }
  }
  required_version = ">= 0.13"
}
