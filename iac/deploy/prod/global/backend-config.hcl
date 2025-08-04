# Backend configuration for prod environment global resources
# This deployment manages resources that span multiple regions
bucket         = "trm-blockexplorer-terraform-state-754419183698-us-west-2"
key            = "environments/prod/global/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "trm-blockexplorer-terraform-locks"
encrypt        = true
kms_key_id     = "65925835-1465-4852-8f5b-f8a5812c159d"