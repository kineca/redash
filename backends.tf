terraform {
  required_version = "1.4.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.60.2"
    }
  }

  backend "gcs" {
    bucket = "cabakuru-analytics-tfstate"
    prefix = "redash"
  }
}
