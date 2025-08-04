# Security Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
  default     = ""
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
  default     = ""
}

variable "create_security_groups" {
  description = "Whether to create security groups"
  type        = bool
  default     = true
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  type        = list(string)
}

variable "create_kms_keys" {
  description = "Whether to create KMS keys"
  type        = bool
  default     = true
}

variable "kms_key_aliases" {
  description = "Map of KMS key aliases to create"
  type        = map(string)
  default = {
    secrets = "secrets-key"
    data    = "data-key"
    logs    = "logs-key"
  }
}

variable "enable_multi_region_keys" {
  description = "Enable multi-region KMS keys"
  type        = bool
  default     = false
}

variable "primary_region" {
  description = "Primary region for multi-region KMS keys"
  type        = string
  default     = "us-west-2"
}

variable "lambda_function_names" {
  description = "List of Lambda function names that need security groups"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}