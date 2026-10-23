terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.8"
    }
  }
}

# The project comes from the GOOGLE_CLOUD_PROJECT environment variable, and
# credentials come from Application Default Credentials (ADC).
provider "google" {
  region = "us-central1"
  zone   = "us-central1-a"
}

# A dedicated VPC network, so the tutorial doesn't depend on the project's default network
resource "google_compute_network" "app" {
  name                    = "iac101-terraform"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "app" {
  name          = "iac101-terraform"
  network       = google_compute_network.app.id
  ip_cidr_range = "10.10.0.0/24"
}

# Allow public traffic to the app port, but only on VMs with this tag
resource "google_compute_firewall" "allow_app" {
  name    = "iac101-terraform-allow-8080"
  network = google_compute_network.app.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["iac101-terraform"]
}

# An e2-micro VM in us-central1 with a 10 GB standard disk fits the Compute Engine Free Tier
resource "google_compute_instance" "app" {
  name         = "iac101-terraform"
  machine_type = "e2-micro"
  tags         = ["iac101-terraform"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app.id
    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = file("${path.module}/startup.sh")
}

output "public_ip" {
  value = google_compute_instance.app.network_interface[0].access_config[0].nat_ip
}

output "app_url" {
  value = "http://${google_compute_instance.app.network_interface[0].access_config[0].nat_ip}:8080"
}
