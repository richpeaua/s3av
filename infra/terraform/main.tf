provider "aws" {
    region = var.aws_region

    # Skips to speed up TF applies
    skip_get_ec2_platforms      = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_credentials_validation = true
}

terraform {
  backend "s3" {
    bucket = var.tf_state_bucket
    key    = var.tf_state_key
    region = var.aws_region
  }
}
