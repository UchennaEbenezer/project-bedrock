output "cluster_endpoint" {
  description = "EKS Cluster API endpoint URL"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
  description = "Name of the EKS Cluster"
  value       = aws_eks_cluster.main.name
}

output "region" {
  description = "AWS Deployment Region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "assets_bucket_name" {
  description = "Name of the S3 assets bucket"
  value       = aws_s3_bucket.assets.id
}

output "dev_access_key_id" {
  description = "Developer Access Key ID"
  value       = aws_iam_access_key.dev_key.id
}

output "dev_secret_access_key" {
  description = "Developer Secret Access Key"
  value       = aws_iam_access_key.dev_key.secret
  sensitive   = true
}

output "dev_console_password" {
  description = "Developer AWS Console Password"
  value       = aws_iam_user_login_profile.dev_login.password
  sensitive   = true
}
