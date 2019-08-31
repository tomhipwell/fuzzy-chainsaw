variable "project_id" {
  description = "The project in which the reverse proxy will be deployed."
}

variable "network" {
  description = "The name of the network to which our resources will be attached."
}

variable "subnet" {
  description = "The subnet on which our managed instance group will sit."
}

variable "zone" {
  description = "GCP resource zone."
}

variable "region" {
  description = "GCP resource region."
}

variable "image_name" {
  description = "The name of the image from the container registry we will deploy."
}

variable "service_name" {
  description = "Name for our service."
}

variable "service_port" {
  description = "The port on which our service will listen."
  default     = "8080"
}

variable "machine_type" {
  description = "Machine build to use for our instance group."
  default     = "g1-small"
}

variable "protocol" {
  description = "Protocol used when communicating with our backend service."
  default     = "HTTP"
}

variable "allowed_ssh_ip_range" {
  type        = "list"
  description = "The allowed ip address range which can ssh to our vms."
}
