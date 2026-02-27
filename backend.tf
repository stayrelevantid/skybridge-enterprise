terraform {
  backend "s3" {
    bucket         = "skybridge-enterprise-stayrelevantid-tfstate" # Harus unik sesuai di bootstrap
    key            = "state/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "skybridge-enterprise-stayrelevantid-tflock"
  }
}
