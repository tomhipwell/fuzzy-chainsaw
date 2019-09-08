variable "short_name" {
  description = "A short name for your project, used for labelling all resources."
}

variable "domain_name" {
  description = "The domain you have bought for this project."
}

module "core_project" {
  source       = "../../projects/core"
  short_name   = "${var.short_name}"
  domain_name  = "${var.domain_name}"
  google_group = "foo@bar.com"
}

output "project" {
  value = "${module.core_project.project}"
}

output "nameservers" {
  value = "${module.core_project.nameservers}"
}

output "static_site_ip" {
  value = "${module.core_project.static_site_ip}"
}

output "static_backend_bucket" {
  value = "${module.core_project.static_backend_bucket}"
}
