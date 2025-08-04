# ECS Deployment Guide

## Building and Deploying to ECS

### Prerequisites
- AWS CLI configured with appropriate credentials
- Docker installed and running
- Access to ECR repository: `754419183698.dkr.ecr.us-west-2.amazonaws.com/trm-blockexplorer`

### Quick Start

#### Option 1: Using the build script
```bash
# Build and push with default 'latest' tag
./scripts/build-and-push-ecr.sh

# Build and push with specific tag
./scripts/build-and-push-ecr.sh v1.0.0
```

#### Option 2: Using Task commands
```bash
# Login to ECR
task docker:ecr:login

# Build and push in one command
task docker:build:push TAG=v1.0.0

# Or separately
task docker:build TAG=v1.0.0
task docker:push TAG=v1.0.0

# Run locally for testing
task docker:run:local
```

### Manual Commands

```bash
# 1. Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 754419183698.dkr.ecr.us-west-2.amazonaws.com

# 2. Build the image
docker build -t 754419183698.dkr.ecr.us-west-2.amazonaws.com/trm-blockexplorer:latest .

# 3. Push to ECR
docker push 754419183698.dkr.ecr.us-west-2.amazonaws.com/trm-blockexplorer:latest
```

### Updating ECS Service

After pushing a new image:

```bash
# Force new deployment with latest image
aws ecs update-service \
  --cluster trm-blockexplorer-dev-cluster \
  --service trm-blockexplorer-api-dev \
  --force-new-deployment \
  --region us-west-2
```

### Container Image URI for Terraform

Use this in your Terraform variables:
```
container_image_uri = "754419183698.dkr.ecr.us-west-2.amazonaws.com/trm-blockexplorer:latest"
```

### Troubleshooting

1. **ECR Login Issues**
   ```bash
   # Ensure AWS CLI is configured
   aws sts get-caller-identity
   ```

2. **Build Failures**
   ```bash
   # Check if requirements.txt exists
   uv pip compile pyproject.toml -o requirements.txt
   ```

3. **ECS Service Not Updating**
   ```bash
   # Check service events
   aws ecs describe-services \
     --cluster trm-blockexplorer-dev-cluster \
     --services trm-blockexplorer-api-dev \
     --region us-west-2
   ```

### Environment Variables

The container expects these environment variables (set by ECS task definition):
- `PROJECT_NAME`
- `ENVIRONMENT`
- `REGION`
- `ADDRESS_WATCHLIST_TABLE`
- `SUSPICIOUS_TRANSACTIONS_TABLE`
- `INVESTIGATION_NOTES_TABLE`
- `INFURA_API_KEY` (from SSM)
- `INFURA_API_SECRET` (from SSM)
