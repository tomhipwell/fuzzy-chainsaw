provider "google-beta" {
  region  = "${var.region}"
  project = "${var.project_id}"
}

variable "region" {
  type        = "string"
  description = "Default region for all resources."
  default     = "europe-west2"
}

variable "zone" {
  type        = "string"
  description = "Default zone for all resources."
  default     = "europe-west2-c"
}

variable "project_name" {
  type        = "string"
  description = "Project name, non-unique."
}

variable "project_id" {
  type        = "string"
  description = "Project id, unique."
}

variable "email" {
  type        = "string"
  description = "Owning email group or email address."
  default     = "foo@bar.com"
}

resource "google_project" "project" {
  name                = "${var.project_name}"
  project_id          = "${var.project_id}"
  auto_create_network = false

  lifecycle {
    ignore_changes = [
      "billing_account",
    ]
  }
}

resource "google_project_services" "project" {
  project = "${google_project.project.project_id}"

  services = [
    "storage-component.googleapis.com",
    "deploymentmanager.googleapis.com",
    "replicapool.googleapis.com",
    "redis.googleapis.com",
    "replicapoolupdater.googleapis.com",
    "resourceviews.googleapis.com",
    "cloudtrace.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "oslogin.googleapis.com",
    "cloudbilling.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "containerregistry.googleapis.com",
    "bigquery-json.googleapis.com",
    "pubsub.googleapis.com",
    "storage-api.googleapis.com",
    "appengine.googleapis.com",
    "stackdriver.googleapis.com",
    "cloudfunctions.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudbuild.googleapis.com",
    "composer.googleapis.com",
    "bigquerystorage.googleapis.com",
    "dns.googleapis.com",
  ]
}

resource "google_project_iam_member" "project_owner" {
  count   = "${var.email != "foo@bar.com" ? 1 : 0}"
  role    = "roles/owner"
  project = "${google_project_services.project.project}"
  member  = "email:${var.email}"

  lifecycle = {
    create_before_destroy = true
  }
}

resource "google_service_account" "terraform_admin" {
  account_id   = "terraform"
  display_name = "terraform"
  project      = "${google_project_services.project.project}"
}

resource "google_project_iam_member" "terraform_owner" {
  role    = "roles/owner"
  project = "${google_project_services.project.project}"
  member  = "serviceAccount:${google_service_account.terraform_admin.email}"

  lifecycle = {
    create_before_destroy = true
  }
}

output "project_id" {
  value = "${google_project_services.project.project}"
}

output "region" {
  value = "${var.region}"
}

output "zone" {
  value = "${var.zone}"
}
