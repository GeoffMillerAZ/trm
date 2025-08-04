# Backend configuration for prod environment us-east-2 region
# This deployment manages region-specific resources in us-east-2
# Note: State bucket is in us-west-2 (primary region)
bucket         = "trm-blockexplorer-terraform-state-754419183698-us-west-2"
key            = "environments/prod/us-east-2/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "trm-blockexplorer-terraform-locks"
encrypt        = true
kms_key_id     = "65925835-1465-4852-8f5b-f8a5812c159d"