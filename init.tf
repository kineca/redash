resource "google_project_service" "cloudapi" {
  service = "cloudapis.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "sqladmin" {
  service = "sqladmin.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "sql_component" {
  service = "sql-component.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "redis" {
  service = "redis.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "cloudrun" {
  service = "run.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "usage" {
  service = "serviceusage.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "network" {
  service = "servicenetworking.googleapis.com"
  disable_dependent_services = false
}
