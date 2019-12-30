resource "random_id" "randomized_project_name" {
  byte_length = 2
  prefix      = "-"
}

module "project" {
  source       = "../modules/project"
  project_name = var.short_name
  project_id   = "${var.short_name}${random_id.randomized_project_name.hex}"
}

module "dns_zone" {
  source     = "../modules/dns_zone"
  short_name = var.short_name
  project_id = module.project.project_id
  domain     = var.domain_name
}

module "vpc" {
  source     = "../modules/vpc"
  project_id = module.project.project_id
  region     = module.project.region
}

module "backend" {
  source     = "../modules/backend"
  short_name = var.short_name
  domain     = module.dns_zone.dns_name
  project_id = module.project.project_id
  region     = module.project.region
}

module "http_redirect" {
  source       = "../modules/managed_instance_group"
  project_id   = module.project.project_id
  service_name = "http-https"
  image_name   = "http-https"
  region       = module.project.region
  zone         = module.project.zone
  network      = module.vpc.network
  subnet       = module.vpc.subnet

  # if you are working with a stable ip address, it is worth restricting this range.
  allowed_ssh_ip_range = ["0.0.0.0/0"]
}

module "frontend" {
  source                = "../modules/frontend_load_balancer"
  project_id            = module.project.project_id
  short_name            = module.backend.short_name
  domain                = module.dns_zone.dns_name
  dns_zone              = module.dns_zone.dns_zone
  region                = module.project.region
  backend_url_map       = module.backend.https_backend_url_map
  http_redirect_backend = module.http_redirect.backend_service
}

