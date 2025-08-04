# OPA Policy Enforcement in CI/CD Pipeline

## Goal
Implement automated Open Policy Agent (OPA) policy validation in the CI/CD pipeline to ensure all Terraform infrastructure changes comply with organizational security, compliance, and best practice policies before deployment, with environment-specific enforcement levels.

## Context
The project has existing OPA policies in `iac/policies/opa/` that define security, compliance, and tagging requirements for AWS infrastructure. These policies need to be integrated into the GitHub Actions workflows to provide automated validation of Terraform plans.

**Current State:**
- OPA policies exist but are not automatically enforced
- No validation of Terraform plans against policies in CI/CD
- Manual policy checking is error-prone and inconsistent
- Different environments (dev/prod) need different enforcement levels

**Business Requirements:**
- **Compliance**: All infrastructure must meet security and compliance standards
- **Early Feedback**: Policy violations detected before deployment
- **Environment Flexibility**: Development allows experimentation with warnings
- **Production Safety**: Production requires strict policy compliance
- **Audit Trail**: Clear record of policy evaluations and decisions

## Requirements

### Functional Requirements

#### Policy Evaluation
- **Terraform Plan Generation**: Generate plans for all affected Terraform projects
- **Policy Loading**: Load all OPA policies from `iac/policies/opa/`
- **Plan Evaluation**: Evaluate Terraform plans (JSON format) against policies
- **Result Aggregation**: Combine results from multiple policy files
- **Environment Context**: Pass environment data to policies for context-aware rules

#### Environment-Specific Behavior
- **Development Environment**:
  - Policy violations displayed as warnings
  - Detailed violation messages in workflow logs
  - Workflow continues despite violations
  - Summary report of all policy issues
  
- **Production Environment**:
  - Policy violations cause workflow failure
  - Blocking violations must be resolved before deployment
  - Manual override requires security team approval
  - Detailed compliance report generated

#### Policy Categories

**Security Policies** (`rules/security/`):

Example - S3 Bucket Encryption:
```rego
package terraform.security.s3

import future.keywords.in

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  not has_encryption(resource)
  msg := sprintf("S3 bucket '%s' must have encryption enabled", [resource.address])
}

has_encryption(resource) {
  resource.change.after.server_side_encryption_configuration[_].rule[_].apply_server_side_encryption_by_default.sse_algorithm != null
}
```

Example - IAM Least Privilege:
```rego
package terraform.security.iam

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_iam_policy"
  policy := json.unmarshal(resource.change.after.policy)
  statement := policy.Statement[_]
  statement.Effect == "Allow"
  action := statement.Action[_]
  action == "*"
  msg := sprintf("IAM policy '%s' uses wildcard actions - apply least privilege", [resource.address])
}
```

**AWS Service Policies** (`rules/aws/`):

Example - Lambda Function Configuration:
```rego
package terraform.aws.lambda

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_lambda_function"
  resource.change.after.timeout > 300
  msg := sprintf("Lambda function '%s' timeout exceeds 5 minutes (300s)", [resource.address])
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_lambda_function"
  not resource.change.after.dead_letter_config
  msg := sprintf("Lambda function '%s' should have a dead letter queue configured", [resource.address])
}
```

**Tagging Policies** (`rules/tags/`):

Example - Required Tags:
```rego
package terraform.tags

required_tags := ["Environment", "Project", "Owner", "CostCenter"]

deny[msg] {
  resource := input.resource_changes[_]
  is_taggable_resource(resource.type)
  missing_tags := required_tags[_]
  not resource.change.after.tags[missing_tags]
  msg := sprintf("Resource '%s' is missing required tag: %s", [resource.address, missing_tags])
}

is_taggable_resource(type) {
  taggable_types := [
    "aws_s3_bucket",
    "aws_lambda_function",
    "aws_dynamodb_table",
    "aws_api_gateway_rest_api"
  ]
  type in taggable_types
}

### Non-Functional Requirements

#### Performance
- **Evaluation Time**: < 30 seconds for typical Terraform plans
- **Parallel Processing**: Evaluate multiple projects concurrently
- **Caching**: Cache OPA binary and policy bundles

#### Reliability
- **Policy Syntax**: Validate policy syntax before evaluation
- **Error Handling**: Graceful handling of malformed plans or policies
- **Fallback**: Clear error messages if OPA evaluation fails

#### Maintainability
- **Policy Testing**: Unit tests for all policy rules
- **Documentation**: Clear documentation for each policy
- **Versioning**: Track policy changes in git

## Acceptance Tests

### PR Workflow Tests
1. Submit PR with compliant Terraform changes
   - Verify OPA evaluation runs successfully
   - Confirm no warnings or errors displayed
   - Validate workflow passes

2. Submit PR with policy violations
   - Verify violations are displayed as warnings
   - Confirm detailed violation messages appear
   - Validate workflow still passes (warnings only)

3. Submit PR modifying multiple Terraform projects
   - Verify all projects are evaluated
   - Confirm results are aggregated correctly
   - Validate performance (< 30 seconds)

### Deployment Workflow Tests
1. Deploy to development with policy violations
   - Verify warnings are displayed prominently
   - Confirm deployment proceeds despite warnings
   - Validate warning summary in job logs

2. Deploy to production with policy violations
   - Verify workflow fails at OPA validation step
   - Confirm clear error messages explain violations
   - Validate deployment is blocked

3. Deploy to production with compliant changes
   - Verify OPA validation passes
   - Confirm no warnings or errors
   - Validate deployment proceeds

### Policy Testing
1. Test security policies
   - Create Terraform plan with overly permissive IAM
   - Verify policy detects and reports violation
   - Confirm specific remediation guidance provided

2. Test tagging policies
   - Create resources missing required tags
   - Verify policy identifies missing tags
   - Confirm tag requirements are clearly stated

3. Test AWS service policies
   - Create S3 bucket without encryption
   - Verify policy requires encryption
   - Confirm policy explains security requirement

## Implementation Details

### Workflow Integration

Complete GitHub Actions job for OPA policy evaluation:
```yaml
opa-policy-check:
  name: OPA Policy Validation
  runs-on: ubuntu-latest
  steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.9.5
    
    - name: Terraform Init
      run: terraform init
      working-directory: ./iac/terraform/projects/${{ matrix.project }}
    
    - name: Terraform Plan
      run: terraform plan -out=tfplan
      working-directory: ./iac/terraform/projects/${{ matrix.project }}
    
    - name: Convert Plan to JSON
      run: terraform show -json tfplan > tfplan.json
      working-directory: ./iac/terraform/projects/${{ matrix.project }}
    
    - name: Setup OPA
      run: |
        curl -L -o opa https://openpolicyagent.org/downloads/v0.64.0/opa_linux_amd64_static
        chmod +x opa
        sudo mv opa /usr/local/bin/
    
    - name: Evaluate OPA Policies
      id: opa-eval
      run: |
        # Set enforcement level based on target environment
        if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
          ENFORCEMENT_LEVEL="strict"
        else
          ENFORCEMENT_LEVEL="warning"
        fi
        
        # Run OPA evaluation
        VIOLATIONS=$(opa eval \
          -d iac/policies/opa \
          -i tfplan.json \
          --format=json \
          "data.terraform.deny[x]" | jq -r '.result[0].expressions[0].value[]')
        
        if [ ! -z "$VIOLATIONS" ]; then
          echo "::group::Policy Violations Found"
          echo "$VIOLATIONS" | jq -r '.'
          echo "::endgroup::"
          
          if [ "$ENFORCEMENT_LEVEL" == "strict" ]; then
            echo "❌ Policy violations found - blocking deployment"
            exit 1
          else
            echo "⚠️ Policy violations found - proceeding with warnings"
          fi
        else
          echo "✅ All policies passed"
        fi
      working-directory: ./iac/terraform/projects/${{ matrix.project }}
```

### Environment-Specific Policy Data
```json
// iac/policies/opa/data/environments.json
{
  "environments": {
    "development": {
      "enforce_encryption": false,
      "max_lambda_timeout": 900,
      "required_tags": ["Environment", "Project"]
    },
    "production": {
      "enforce_encryption": true,
      "max_lambda_timeout": 300,
      "required_tags": ["Environment", "Project", "Owner", "CostCenter"]
    }
  }
}

### Policy Data Files
- `environments.json`: Environment-specific configuration
- `helpers.rego`: Shared policy functions
- `main.rego`: Policy aggregation and main entry point

## Success Metrics
- **Policy Coverage**: 100% of Terraform deployments validated
- **Violation Detection**: 95%+ of policy violations caught before deployment
- **Developer Experience**: < 2 minute additional time for policy evaluation
- **Compliance Rate**: 99%+ production deployments comply with policies
- **False Positive Rate**: < 5% of violations are false positives

## Migration Plan
1. Phase 1: Add OPA validation to PR workflow (warnings only)
2. Phase 2: Monitor and refine policies based on warnings
3. Phase 3: Enable strict enforcement for production deployments
4. Phase 4: Add custom policies for organization-specific requirements