module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "2.11.1"
  

  bucket        = "${var.app_env}-${var.app_name}-${var.s3_scan_bucket_name}"
  acl           = "private"
  policy        = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${var.app_env}-${var.app_name}-${var.s3_scan_bucket_name}/*"
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/S3AVScanStatus": "INFECTED"
        }
      }
    }
  ]
}
EOF

  versioning = {
    enabled = true
  }
}


module "s3_event" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "2.11.1"

  bucket     = module.s3_bucket.s3_bucket_id
  bucket_arn = module.s3_bucket.s3_bucket_arn

  lambda_notifications = {
    scanner = {
      function_arn  = module.lambda_scanner.lambda_function_arn
      function_name = module.lambda_scanner.lambda_function_name
      events        = ["s3:ObjectCreated:*"]
    }
  }
}
