provider "aws" {
  region = "ap-southeast-1"
}

# Create S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "skybridge-enterprise-stayrelevantid-tfstate"
  force_destroy = true # Diperuntukkan untuk lab agar bisa di destroy
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create DynamoDB Table for Terraform State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "skybridge-enterprise-stayrelevantid-tflock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
}
