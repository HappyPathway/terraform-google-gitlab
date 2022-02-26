provider "google" {
    project = "hf-tf-d-tech-dave-git-sandbox"
}

provider "google-beta" {
   project = "hf-tf-d-tech-dave-git-sandbox"
}

terraform {
  required_providers {
    google = {
      version = "3.36.0"
    }
  }
}
