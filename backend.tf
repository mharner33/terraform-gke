terraform {
  backend "gcs" {
    bucket = "{bucket-name}"
    prefix = "tfstate"
  }
}