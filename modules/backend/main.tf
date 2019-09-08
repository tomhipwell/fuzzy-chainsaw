provider "google-beta" {
  region  = "${var.region}"
  project = "${var.project_id}"
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

resource "google_storage_bucket" "static_pages" {
  name     = "${var.project_id}-${var.short_name}-static-pages"
  location = "EU"
  project  = "${var.project_id}"

  versioning {
    enabled = true
  }

  website {
    main_page_suffix = "index.html"
  }
}

resource "google_compute_backend_bucket" "static" {
  name        = "static-site-${var.short_name}-backend-bucket"
  project     = "${var.project_id}"
  bucket_name = "${google_storage_bucket.static_pages.name}"
  enable_cdn  = true
}

resource "google_compute_url_map" "urlmap" {
  name            = "${var.short_name}-urlmap"
  project         = "${var.project_id}"
  default_service = "${google_compute_backend_bucket.static.self_link}"

  host_rule {
    hosts        = ["${var.domain}", "www.${var.domain}"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = "${google_compute_backend_bucket.static.self_link}"

    path_rule {
      paths   = ["/*"]
      service = "${google_compute_backend_bucket.static.self_link}"
    }
  }
}

output "short_name" {
  value = "${var.short_name}"
}

output "https_backend_url_map" {
  value = "${google_compute_url_map.urlmap.self_link}"
}

output "static_backend_bucket" {
  value = "${google_storage_bucket.static_pages.name}"
}
