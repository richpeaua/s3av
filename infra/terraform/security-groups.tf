# TODO: Limit access
resource "aws_security_group" "lambda_scanner" {
  count       = var.scanner_enabled ? 1 : 0
  name        = "${var.app_env}-${var.app_name}-lambda-${substr(uuid(), 0, 2)}"
  description = "S3 Virus Scanner Lambda node security groups"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }

  tags = merge({
    "Name" = "${var.app_env}-${var.app_name}-lambda-scanner"
    },
    var.tags
  )
}
