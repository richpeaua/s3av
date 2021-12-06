module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"
  
  name            = '${var.env}-${var.app_name}-vpc'
  create_vpc      = var.vpc_create
  azs             = var.vpc_azs
  cidr            = var.vpc_cidr
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets
  tags            = var.tags

  # Nat Gateway
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  # VPC endpoints
  enable_s3_endpoint = var.vpc_enable_s3_endpoint
}
