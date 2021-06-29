resource "random_password" "postgres_user_freshrss" {
  length  = 12
  special = false
}

resource "postgresql_role" "freshrss" {
  name     = "freshrss"
  login    = true
  password = random_password.postgres_user_freshrss.result
}

resource "postgresql_database" "freshrss" {
  name  = "freshrss"
  owner = postgresql_role.freshrss.name
}
