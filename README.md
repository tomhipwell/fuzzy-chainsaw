# fuzzy-chainsaw

This repo builds a highly scalable, highly available and super cheap hosted static site, using a GCS bucket as the backend. There is edge caching for global content distribution and a https load balancer is deployed to terminate the SSL (TLS) connection from the client. SSL certificate issuance is handled for you. An nginx http redirect is deployed and run by an auto-scaling managed instance group so that all connections are always forwarded to https. A managed dns zone and dns records are created for your site, alongside CNAME records for the www subdomain.

The infrastructure has a modular design, so as you need to grow you can switch out the modules rather than having to restructure all of your cloud resources or migrate between cloud providers. The initial setup is very similar to what you get from Netlify for static site hosting.

## Billing

This project uses billed features on GCP. If you don't want to be charged, remember to tear down the environment once you are done with your development. If you'd like to enable billing, see the subsection below ('Enabling Billing').

Note terraform apply will fail the first time it is run unless billing is enabled for the project you create.

## Getting Started

You'll need to install terraform and the gcloud SDK. I'd also recommend installing tfswitch so you can control the terraform version that you are using. The following commands assume you're on Mac OS and have homebrew installed:

```shell
brew install terraform
brew cask install google-cloud-sdk
brew install warrensbox/tap/tfswitch
brew install docker
```

Temporaily set your gcloud credentials gcloud auth application-default login:

```shell
gcloud auth application-default login
```

The above command will also print to std out a path to a json file, set the google application credentials environment variable used by terraform:

```shell
export GOOGLE_APPLICATION_CREDENTIALS=~/path/to/my/credentials.json
```

Set your working directory to ./environments/prod and run:

```shell
terraform init
```

This writes a terraform statefile locally on your machine. Note, if you want to productionize this codebase, you might want to move your statefile to be stored in a Cloud Storage Bucket, as then you can put in place a locking mechanism in place to prevent conflicts created by multiple peeps working on the codebase at the same time (see the subsection, "Backend").

If you've previously init'd your dir locally, make sure you run:

```shell
terraform refresh
```

To update your local state before starting work.

Before we go further, make sure you have two things in place. Firstly, go register the domain you want to work with. Once that's done, run the plan command targetting the project module only:

```shell
terraform plan -target module.core_project.module.project -out tfout
```

This command creates a plan object for what will happen when your changes get applied. Note that you're prompted for two variables - the domain name you have registed, and a short name to use for all the terraform resources. Set these based on whatever you want to use. Review your changes carefully - plan works by comparing the GCP project state to that defined in your code. If you're happy with the changes that will be made, then run:

```shell
terraform apply "tfout"
```

If the apply applies fails, skip to the next section of the documentation.

This will apply your changes in the environment you have selected. Note that terraform is built around the concept of immutable infrastructure. So if your resources already exist, they will always be set to the state defined in code. This means that if you go and make a manual change to a GCP project through the Cloud Console those changes will be lost the next time terraform apply is run.

## Enabling Billing

The terraform apply will fail the first time that you run the terraform codebase. This is because billing will not be enabled for the project you create. You can enable billing from the command line. First, check that you have a billing account configured:

```shell
# list your billing accounts
gcloud alpha billing accounts list
```

If you don't use your google foo to figure out how to do this. Once you have a billing account configured, link it to your project:

```shell
# list your projects
gcloud projects list
# link your project
gcloud alpha billing projects link my-project \
      --billing-account 0X0X0X-0X0X0X-0X0X0X
```

This can also be done directly in terraform so that your terraform apply works first time. Just adjust the project resource block to include a billing attribute as follows (note the removal of the lifecycle block):

```terraform
data "google_billing_account" "acct" {
  display_name = "my-billing-account"
  open         = true
}

resource "google_project" "project" {
  name                = "${var.project_name}"
  project_id          = "${var.project_id}"
  billing_account     = "${data.google_billing_account.acct.id}"
  auto_create_network = true
}
```

## Pushing our nginx image to the project container registry

Once you've setup your project for billing, you should be able to contiue with the resource build out. Start by running terraform apply again to complete the build of the project module:

```shell
terraform apply -target module.core_project.module.project
```

Once this is done, we'll have a container registry available to us to host our docker images. We need to deploy our docker image for our nginx http redirect service to this registry. First, build the image. To do this, from the root directory run:

```shell
docker image build -t http-https ./containers/nginx/
```

Next, if you haven't already, configure your docker to use the gcloud credential helper:

```shell
gcloud auth configure-docker
```

Then tag your docker image with the container registry name, for example:

```shell
docker tag http-https eu.gcr.io/"$PROJECT"/http-https
```

Where $PROJECT is the id of your gcp project. Push the tagged image to the container registry:

```shell
docker push eu.gcr.io/"$PROJECT"/http-https
```

Now our image is pushed to our container registry, we can deploy the our managed instance group and the rest of our terraform resources. If you haven't already, this might be a nice time to add defaults to the short_name and domain variables in the /environments/prod main.tf file, a bit like this:

```terraform
variable "short_name" {
  description = "A short name for your project, used for labelling all resources."
  default     = "foobar"
}

variable "domain_name" {
  description = "The domain you have bought for this project."
  default     = "foobar.com"
}
```

Check in your change to your fork, then check the plan again and if you're happy, proceed and apply the changes:

```shell
terraform plan -out tfout
terraform apply "tfout"
```

Once that completes, the bucket should print to screen. Export the bucket name as an environment variable and run:

```shell
echo 'hello world!' > index.html && gsutil cp index.html gs://"$BUCKET"
```

From this point forwards just use gsutil to deploy your site.

Also printed to screen from terrform output is the nameservers for your site - you'll need to go set these correctly with your registrar for your DNS records to resolve correctly.

## Outputs

You can get output variables from Terraform using the command:

```shell
terraform output
```

## Switching to a service account when using terraform

Once you've setup your initial project, you can then switch to using a service account that gets setup as part of the GCP project to administer it.

```shell
export PROJECT_ID=my-project-id
gcloud iam service-accounts keys create key.json
    --iam-account=terraform@"$PROJECT_ID".iam.gserviceaccount.com
export GOOGLE_APPLICATION_CREDENTIALS=key.json
```

You can also switch to use the service account your shell (useful for testing):

```shell
gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS
```

## Backend

The sample code is intended as a lightweight demo project. If you want to industrialise it, I'd suggest creating a dedicated terraform project to host a service account which has rights to create/destroy projects within your organsation, and also a storage bucket which you can use as a backend for your terraform state file. Use your google foo to find instructions on how to do this, then just add a backend block to the main.tf and you should be away:

```terraform
terraform {
  backend "gcs" {
    bucket  = "my-terraform-admin-bucket"
    prefix  = "terraform/state"
    project = "my-terraform-admin-project"
  }
}
```

## Destroy

Proceed with caution, but you can tear down a test environment by using:

```shell
terraform destroy
```

## Debugging

You can debug the terraform code by setting the \$TF_LOG and TF_LOG_PATH env vars. There are four main log levels - ERROR, DEBUG, TRACE, INFO. If you use DEBUG, http requests are logged with host/endpoint/request.

```shell
export TF_LOG=DEBUG
```

## Viewing the Terraform Graph

Terraform is using a DAG behind the scenes to map the relationship between the resources you have defined. It's important to understand how this is hanging together, as it impacts how terraform will go deploy your changes at apply time. You can view this graph with the command:

```shell
terraform graph
```

If you have graphviz on your machine, you can visualise the graph:

```shell
terraform graph | dot -Tpng > graph.png
```

The terraform graph is always computed on the fly from your local configurations files, so checking this quickly after you have completed your code changes is a good post-release step.
