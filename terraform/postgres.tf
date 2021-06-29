output "postgres_internal_ip" {
  value = [
    for net in docker_container.postgres.network_data :
    net.ip_address
    if net.network_name == docker_network.postgres.name
  ][0]
}

resource "docker_image" "postgres" {
  name = "postgres:13"
}

resource "docker_volume" "postgres" {
  name = "postgres"
}

resource "docker_network" "postgres" {
  name = "postgres"
}

resource "random_password" "postgres_user_postgres" {
  length  = 12
  special = false
}

resource "docker_container" "postgres" {
  name  = "postgres"
  image = docker_image.postgres.latest

  env = toset([
    "POSTGRES_PASSWORD=${random_password.postgres_user_postgres.result}"
  ])

  restart = "unless-stopped"

  mounts {
    target = "/var/lib/postgresql/data"
    type   = "volume"
    source = docker_volume.postgres.name
  }

  networks_advanced {
    name = docker_network.postgres.name
  }
}

provider "postgresql" {
  host     = "127.0.0.1"
  port     = var.postgres_port
  password = random_password.postgres_user_postgres.result
  sslmode  = "disable"
}
