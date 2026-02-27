# Ambil AMI Amazon Linux 2023 terbaru secara dinamis
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# -------------------------------------------------------------
# APPLICATION LOAD BALANCER (ALB)
# -------------------------------------------------------------
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name    = "${local.project_name}-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  # Menempelkan Security Group khusus ALB
  security_groups = [module.alb_sg.security_group_id]

  # Listerner HTTP (Menerima trafik dari publik di port 80)
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "app_tg"
      }
    }
  }

  # Target Group mengarah ke Auto Scaling Group EC2
  target_groups = {
    app_tg = {
      name_prefix      = "app-"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      create_attachment= false # ASG yg akan secara otomatis me-_register_ instances ke TG ini
      
      # Strategi Health Check
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/" # Mengecek halaman depan Nginx
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  }

  tags = local.common_tags
}

# -------------------------------------------------------------
# AUTO SCALING GROUP (ASG) & LAUNCH TEMPLATE
# -------------------------------------------------------------
# Script sederhana untuk menginstall Nginx (Bisa dimodif untuk mensimulasikan App Redeploy)
locals {
  user_data = <<-EOT
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    
    # Custom HTML content to visually verify Load Balancing
    echo "<h1>Welcome to SkyBridge Enterprise!</h1>" | sudo tee /usr/share/nginx/html/index.html
    echo "<p>Served by EC2 Instance: $(hostname -f)</p>" | sudo tee -a /usr/share/nginx/html/index.html
    echo "<p>Application Version: v1.0</p>" | sudo tee -a /usr/share/nginx/html/index.html
  EOT
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 8.0"

  name = "${local.project_name}-asg"

  # ASG Scaling Policy
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = module.vpc.private_subnets
  health_check_type         = "ELB" # Mengandalkan Load Balancer Health Check
  # Menggunakan traffic source attachments (Modul ASG v8+)
  traffic_source_attachments = {
    alb = {
      traffic_source_identifier = module.alb.target_groups["app_tg"].arn
      traffic_source_type       = "elbv2"
    }
  }

  # Launch Template Configuration
  launch_template_name        = "${local.project_name}-lt"
  launch_template_description = "Launch Template for Nginx Web Server"
  update_default_version      = true

  # Amazon Linux 2023 AMI (Dinamis dari Data Source)

  # Amazon Linux 2023 AMI (Dinamis dari Data Source)
  image_id          = data.aws_ami.amazon_linux.id
  instance_type     = "t3.micro"
  
  # Menempelkan Security Group khusus EC2 (hanya dari ALB)
  security_groups   = [module.ec2_sg.security_group_id]

  # IAM Role & Instance Profile untuk Systems Manager (SSM) memampukan akses SSH via browser
  create_iam_instance_profile = true
  iam_role_name               = "${local.project_name}-ec2-ssm-role"
  iam_role_description        = "IAM role for EC2 instances to allow SSM (SSH) access"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # Script instalasi Nginx
  user_data         = base64encode(local.user_data)
  
  # Auto-scaling instance refresh untuk zero-downtime deployment
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 50
    }
    triggers = ["tag"] # Terapkan refresh saat ada perubahan tag / config
  }

  tags = local.common_tags
}

# Output untuk mempermudah testing ALB DNS via browser
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}
