module "core_project" {
  source       = "../../projects/core"
  short_name   = "example"
  domain_name  = "example.com"
  google_group = "foo@bar.com"
}
