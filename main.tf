resource "random_id" "randomized_project_name" {
  byte_length = 2
  prefix      = "-"
}

variable "site_name" {
  description = "The name pf the site we want to build."
}

variable "domain_name" {
  description = "The registered domain."
}

variable "google_group" {
  description = "Private google group to represent owners of the project."
}

module "project" {
  source       = "./modules/project"
  project_name = "${var.site_name}"
  project_id   = "${var.site_name}${random_id.randomized_project_name.hex}"
  email        = "${var.google_group}"
}

module "dns_zone" {
  source     = "./modules/dns_zone"
  project_id = "${module.project.project_id}"
  domain     = "${var.domain_name}"
}

module "vpc" {
  source     = "./modules/vpc"
  project_id = "${module.project.project_id}"
  region     = "${module.project.region}"
}

module "backend" {
  source     = "./modules/backend"
  short_name = "example"
  domain     = "${module.dns_zone.dns_name}"
  project_id = "${module.project.project_id}"
  region     = "${module.project.region}"
}

module "http_redirect" {
  source               = "./modules/managed_instance_group"
  project_id           = "${module.project.project_id}"
  service_name         = "http-https"
  image_name           = "http-https"
  region               = "${module.project.region}"
  zone                 = "${module.project.zone}"
  network              = "${module.vpc.network}"
  subnet               = "${module.vpc.subnet}"
  allowed_ssh_ip_range = []
}

module "frontend" {
  source                = "./modules/frontend"
  project_id            = "${module.project.project_id}"
  short_name            = "${module.backend.short_name}"
  domain                = "${module.dns_zone.dns_name}"
  dns_zone              = "${module.dns_zone.dns_zone}"
  region                = "${module.project.region}"
  backend_url_map       = "${module.backend.https_backend_url_map}"
  http_redirect_backend = "${module.http_redirect.backend_service}"
}
