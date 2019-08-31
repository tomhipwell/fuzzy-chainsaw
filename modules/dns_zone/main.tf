variable "project_id" {
  type        = "string"
  description = "GCP unique project id."
}

variable "domain" {
  type    = "string"
  default = "Domain name"
}

resource "google_dns_managed_zone" "frontend_zone" {
  name     = "${var.domain}-zone"
  dns_name = "${var.domain}"
  project  = "${var.project_id}"
}

output "nameservers" {
  value = "${google_dns_managed_zone.frontend_zone.name_servers}"
}

output "dns_zone" {
  value = "${google_dns_managed_zone.frontend_zone.name}"
}

output "dns_name" {
  value = "${google_dns_managed_zone.frontend_zone.dns_name}"
}
