locals {
  project_name = "SkyBridge-Enterprise"
  owner        = "stayrelevantid"
  environment  = "Production-Lab"

  common_tags = {
    Project           = local.project_name
    Owner             = local.owner
    Environment       = local.environment
    ManagedBy         = "Terraform"
    CostCenter        = "DevOps-Learning"
    DeletionPriority  = "High" # Penanda untuk audit pembersihan
  }
}
