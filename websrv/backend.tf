# --- root/backend.tf ---

terraform {
  backend "s3" {
    bucket = "iaac-backend-uat"
    key    = "remote.tfstate"
    region = "us-east-1"
  }
}
