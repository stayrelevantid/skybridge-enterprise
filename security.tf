# Security Group untuk Application Load Balancer (ALB)
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.project_name}-alb-sg"
  description = "Security Group for ALB - Allow HTTP from anywhere"
  vpc_id      = module.vpc.vpc_id

  # Ingress Rules: Buka port 80 (HTTP) dari internet
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP access from the internet"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  # Egress Rules: Buka semua port keluar (untuk ALB komunikasi ke EC2)
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = local.common_tags
}

# Security Group untuk EC2 Instances dalam Auto Scaling Group (ASG)
module "ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.project_name}-ec2-sg"
  description = "Security Group for EC2 instances - Allow HTTP strictly from ALB only"
  vpc_id      = module.vpc.vpc_id

  # Ingress Rules: Buka port 80, TAPI HANYA dari ALB Security Group (Bukan dari Internet langsung)
  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "Allow HTTP access only from ALB"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]

  # Egress Rules: Buka semua port keluar (Untuk download package Nginx via NAT Gateway)
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = local.common_tags
}
