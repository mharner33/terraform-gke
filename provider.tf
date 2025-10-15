terraform {
required_version = "~> 1.13.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.7.0"
    }
    #helm = {
    #  source  = "hashicorp/helm"
    #   version = "~> 3.0.2"
    #}
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}