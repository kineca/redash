resource "google_sql_database_instance" "redash" {
  project          = var.project_id
  name             = "redash"
  region           = var.region
  database_version = "POSTGRES_14"

  settings {
    tier = "db-custom-1-3840"

    ip_configuration {
      ipv4_enabled   = false
      private_network = "projects/cabakuru-analytics/global/networks/default"
    }

    backup_configuration {
      enabled = true
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "redash_db" {
  name      = "redash"
  instance  = google_sql_database_instance.redash.name
  charset   = "utf8"
  collation = "en_US.UTF8"
}

resource "google_sql_user" "redash_user" {
  name     = "redash"
  password = "redash"
  instance = google_sql_database_instance.redash.name
}
