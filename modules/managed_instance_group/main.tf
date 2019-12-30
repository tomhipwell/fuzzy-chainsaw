provider "google-beta" {
  region  = var.region
  version = "~> 2.0"
}

data "google_compute_image" "coreos" {
  family  = "cos-stable"
  project = "cos-cloud"
}

data "template_file" "instance_template" {
  template = file("${path.module}/container_declaration.yaml")

  vars = {
    project      = var.project_id
    image_name   = var.image_name
    service_name = var.service_name
  }
}

resource "google_compute_instance_template" "default" {
  project      = var.project_id
  provider     = google-beta
  name_prefix  = var.service_name
  machine_type = var.machine_type
  region       = var.region
  tags         = [var.service_name]

  network_interface {
    subnetwork = var.subnet

    access_config {
      network_tier = "PREMIUM"
    }
  }

  disk {
    boot         = true
    source_image = data.google_compute_image.coreos.self_link
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  metadata = {
    gce-container-declaration = data.template_file.instance_template.rendered
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_health_check" "healthz" {
  name     = "${var.service_name}-http-healthz"
  project  = var.project_id
  provider = google-beta

  check_interval_sec  = "10"
  timeout_sec         = "5"
  healthy_threshold   = "2"
  unhealthy_threshold = "3"

  http_health_check {
    port         = "8080"
    request_path = "/healthz"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "manager" {
  project            = var.project_id
  provider           = google-beta
  name               = "${var.service_name}-instance-manager"
  wait_for_instances = false
  base_instance_name = var.service_name

  zone = var.zone

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_percent     = 20
    max_unavailable_fixed = 2
    min_ready_sec         = 60
  }

  version {
    name              = var.service_name
    instance_template = google_compute_instance_template.default.self_link
  }

  named_port {
    name = var.service_name
    port = var.service_port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.healthz.self_link
    initial_delay_sec = "180"
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name     = var.service_name
  zone     = var.zone
  project  = var.project_id
  provider = google-beta
  target   = google_compute_instance_group_manager.manager.self_link

  autoscaling_policy {
    max_replicas    = "18"
    min_replicas    = "1"
    cooldown_period = "60"

    cpu_utilization {
      target = "0.80"
    }
  }
}

resource "google_compute_backend_service" "default" {
  project       = var.project_id
  name          = "${var.service_name}-backend-service"
  health_checks = [google_compute_health_check.healthz.self_link]
  port_name     = var.service_name
  protocol      = var.protocol
  enable_cdn    = true

  backend {
    group = google_compute_instance_group_manager.manager.instance_group
  }
}

resource "google_compute_firewall" "allow_health_check" {
  project = var.project_id
  name    = "${var.service_name}-health-check-allowed"
  network = var.network

  allow {
    protocol = "tcp"
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = [var.service_name]
}

resource "google_compute_firewall" "allow_ssh" {
  project = var.project_id
  name    = "${var.service_name}-ssh-allowed"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_ip_range
  target_tags   = [var.service_name]
}

resource "google_compute_firewall" "allow_http" {
  project = var.project_id
  name    = "${var.service_name}-http-allowed"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.service_name]
}

output "backend_service" {
  value = google_compute_backend_service.default.self_link
}

