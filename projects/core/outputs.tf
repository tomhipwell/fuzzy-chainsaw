output "nameservers" {
  value = "${module.dns_zone.nameservers}"
}

output "static_site_ip" {
  value = "${module.frontend.static_external_ip}"
}

output "static_backend_bucket" {
  value = "${module.backend.static_backend_bucket}"
}

output "project" {
  value = "${module.project.project_id}"
}
