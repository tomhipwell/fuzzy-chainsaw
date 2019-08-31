variable "project_id" {
  description = "Unique name for GCP project."
}

variable "region" {
  description = "Default region for all resources."
}

resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-core-vpc"
  project                 = "${var.project_id}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-core-subnet"
  ip_cidr_range = "10.10.0.0/16"
  region        = "${var.region}"
  project       = "${var.project_id}"
  network       = "${google_compute_network.vpc.self_link}"
}

output "network" {
  value = "${google_compute_network.vpc.self_link}"
}

output "subnet" {
  value = "${google_compute_subnetwork.subnet.self_link}"
}
