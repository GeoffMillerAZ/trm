# Backend configuration for account-bootstrap deployment
# This deployment manages the foundational security services
bucket         = "trm-blockexplorer-terraform-state-754419183698-us-west-2"
key            = "account-bootstrap/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "trm-blockexplorer-terraform-locks"
encrypt        = true
kms_key_id     = "65925835-1465-4852-8f5b-f8a5812c159d"