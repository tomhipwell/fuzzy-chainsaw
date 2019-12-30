variable "project_id" {
  type        = string
  description = "GCP unique project id."
}

variable "domain" {
  type    = string
  default = "Domain name"
}

variable "short_name" {
  type        = string
  description = "Short label to identify terraform resources."
}

resource "google_dns_managed_zone" "frontend_zone" {
  name     = "${var.short_name}-zone"
  dns_name = "${var.domain}."
  project  = var.project_id
}

output "nameservers" {
  value = google_dns_managed_zone.frontend_zone.name_servers
}

output "dns_zone" {
  value = google_dns_managed_zone.frontend_zone.name
}

output "dns_name" {
  value = google_dns_managed_zone.frontend_zone.dns_name
}

