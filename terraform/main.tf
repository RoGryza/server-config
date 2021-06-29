variable "region" {
  default = "lon1"
}

variable "docker_host" {
  type    = string
  default = ""
}

variable "postgres_port" {
  type    = number
  default = 0
}

provider "digitalocean" {
}

provider "docker" {
  host = var.docker_host
}
