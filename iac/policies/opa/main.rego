package main

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Import all policy modules
import data.terraform.security.aws.s3 as s3
import data.terraform.security.aws.lambda as lambda
import data.terraform.security.aws.dynamodb as dynamodb
import data.terraform.security.aws.kms as kms
import data.terraform.security.aws.apigateway as apigateway
import data.terraform.security.iam as iam
import data.terraform.security.network as network
import data.terraform.security.tags as tags

# Collect all denials
deny contains msg if {
    msg := s3.deny[_]
}

deny contains msg if {
    msg := lambda.deny[_]
}

deny contains msg if {
    msg := dynamodb.deny[_]
}

deny contains msg if {
    msg := kms.deny[_]
}

deny contains msg if {
    msg := apigateway.deny[_]
}

deny contains msg if {
    msg := iam.deny[_]
}

deny contains msg if {
    msg := network.deny[_]
}

deny contains msg if {
    msg := tags.deny[_]
}

# Collect all warnings
warn contains msg if {
    msg := s3.warn[_]
}

warn contains msg if {
    msg := lambda.warn[_]
}

warn contains msg if {
    msg := dynamodb.warn[_]
}

warn contains msg if {
    msg := kms.warn[_]
}

warn contains msg if {
    msg := apigateway.warn[_]
}

warn contains msg if {
    msg := network.warn[_]
}

# Summary rule for overall compliance
compliance_summary := {
    "errors": count(deny),
    "warnings": count(warn),
    "passed": count(deny) == 0
}