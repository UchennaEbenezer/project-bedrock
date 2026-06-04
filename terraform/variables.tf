variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "The AWS region to deploy resources in"
}

variable "insecure_ssl" {
  type        = bool
  default     = false
  description = "Bypass SSL verification for AWS API calls locally"
}

variable "cluster_name" {
  type        = string
  default     = "project-bedrock-cluster"
  description = "Name of the EKS cluster"
}

variable "vpc_name" {
  type        = string
  default     = "project-bedrock-vpc"
  description = "Value of the Name tag for the VPC"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Deployment environment"
}

variable "student_id" {
  type        = string
  default     = "alt-soe-025-5599"
  description = "Unique Student ID"
}

variable "namespace" {
  type        = string
  default     = "retail-app"
  description = "Kubernetes namespace for the retail application"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.100.0.0/16"
  description = "CIDR block for the VPC"
}

variable "public_subnets" {
  type        = list(string)
  default     = ["10.100.1.0/24", "10.100.2.0/24"]
  description = "CIDR blocks for public subnets"
}

variable "private_subnets" {
  type        = list(string)
  default     = ["10.100.3.0/24", "10.100.4.0/24"]
  description = "CIDR blocks for private subnets"
}

variable "eks_version" {
  type        = string
  default     = "1.34"
  description = "EKS Cluster Kubernetes version"
}

variable "db_username" {
  type        = string
  default     = "dbadmin"
  description = "Administrator username for RDS databases"
}
