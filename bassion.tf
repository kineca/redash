resource "google_compute_address" "bastion_ip" {
  name = "bastion-ip"
}

data "external" "emuesuenu_public_key" {
  program = ["bash", "-c", "curl -s https://github.com/emuesuenu.keys | jq -R -s -c '{\"public_key\": .}'"]
}

resource "google_compute_instance" "bastion" {
  name         = "bastion-instance"
  machine_type = "n2-standard-2"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-jammy-v20230415"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.bastion_ip.address
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${data.external.emuesuenu_public_key.result["public_key"]}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y redis-tools postgresql-client
  EOT

  allow_stopping_for_update = true
}

output "bastion_ip" {
  value = google_compute_address.bastion_ip.address
}
