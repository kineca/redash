resource "random_password" "cookie_secret" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}