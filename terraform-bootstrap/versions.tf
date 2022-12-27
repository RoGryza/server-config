# TODO can we share deps with the other terraform folder?
terraform {
  required_providers {
    b2 = {
      source = "Backblaze/b2"
    }
  }
  required_version = ">= 1.0"
}
