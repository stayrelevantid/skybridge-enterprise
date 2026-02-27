module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs = ["ap-southeast-1a", "ap-southeast-1b"]
  
  # Public Tier: 2 Subnet (ALB + NAT Gateway)
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  
  # Private App Tier: 2 Subnet (ASG + EC2 Nginx)
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  
  # Private Data Tier: 2 Subnet (Isolasi Database / Optional untuk EC2 tanpa Inet)
  database_subnets = ["10.0.5.0/24", "10.0.6.0/24"]

  # Internet Access Configuration
  create_igw         = true
  enable_nat_gateway = true
  single_nat_gateway = true  # Menghemat biaya (1 NAT Gateway untuk semua private subnet)

  # DNS Support
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tagging Audit
  tags            = local.common_tags
  public_subnet_tags = {
    Type = "Public-ALB-Tier"
  }
  private_subnet_tags = {
    Type = "Private-App-Tier"
  }
  database_subnet_tags = {
    Type = "Private-Data-Tier"
  }
}
