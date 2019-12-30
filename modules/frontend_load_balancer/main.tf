provider "google-beta" {
  region  = var.region
  project = var.project_id
  version = "~> 2.0"
}

variable "short_name" {
  description = "Short name for all resources."
}

variable "project_id" {
  description = "The satellite project id in which out bucket is hosted."
}

variable "region" {
  description = "Default region for our module."
  default     = "europe-west2"
}

variable "domain" {
  description = "Domain, registered elsewhere."
}

variable "dns_zone" {
  description = "The name of the managed dns zone we are using."
}

variable "backend_url_map" {
  description = "Self link for the URL map linking backend paths and services."
}

variable "http_redirect_backend" {
  description = "Backend service to handle http redirection."
}

resource "google_compute_global_address" "static_external_ip" {
  project = var.project_id
  name    = "static-${var.short_name}-ext-ip"
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name    = "${var.short_name}-https-proxy"
  project = var.project_id
  url_map = var.backend_url_map

  ssl_certificates = [
    google_compute_managed_ssl_certificate.ssl_cert.self_link,
    google_compute_managed_ssl_certificate.www_ssl_cert.self_link,
  ]
}

resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  provider = google-beta
  project  = var.project_id
  name     = "${var.short_name}-ssl-cert"

  managed {
    domains = [var.domain]
  }
}

resource "google_compute_managed_ssl_certificate" "www_ssl_cert" {
  provider = google-beta
  project  = var.project_id
  name     = "www-${var.short_name}-ssl-cert"

  managed {
    domains = ["www.${var.domain}"]
  }
}

resource "google_compute_target_http_proxy" "http_proxy" {
  project = var.project_id
  name    = "${var.short_name}-http-proxy"
  url_map = google_compute_url_map.http_redirect.self_link
}

resource "google_compute_url_map" "http_redirect" {
  name            = "http-redirect-urlmap"
  project         = var.project_id
  default_service = var.http_redirect_backend

  host_rule {
    hosts        = [var.domain, "www.${var.domain}"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = var.http_redirect_backend

    path_rule {
      paths   = ["/*"]
      service = var.http_redirect_backend
    }
  }
}

resource "google_compute_global_forwarding_rule" "http" {
  project    = var.project_id
  name       = "${var.short_name}-http"
  target     = google_compute_target_http_proxy.http_proxy.self_link
  ip_address = google_compute_global_address.static_external_ip.address
  port_range = "80"
}

resource "google_compute_global_forwarding_rule" "https" {
  project    = var.project_id
  name       = "${var.short_name}-https"
  target     = google_compute_target_https_proxy.https_proxy.self_link
  ip_address = google_compute_global_address.static_external_ip.address
  port_range = "443"
}

resource "google_dns_record_set" "a" {
  project      = var.project_id
  name         = var.domain
  managed_zone = var.dns_zone
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.static_external_ip.address]
}

resource "google_dns_record_set" "cname" {
  project      = var.project_id
  name         = "www.${var.domain}"
  managed_zone = var.dns_zone
  type         = "CNAME"
  ttl          = 300
  rrdatas      = [var.domain]
}

output "static_external_ip" {
  value = google_compute_global_address.static_external_ip.address
}

