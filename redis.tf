resource "google_redis_instance" "redash_redis" {
  name           = "redash"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.region
}
