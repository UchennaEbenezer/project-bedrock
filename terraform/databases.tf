# DB Subnet Group
resource "aws_db_subnet_group" "db_subnet" {
  name       = "project-bedrock-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "project-bedrock-db-subnet-group"
  }
}

# DB Security Group
resource "aws_security_group" "db_sg" {
  name        = "project-bedrock-db-sg"
  description = "Security group for managed RDS databases"
  vpc_id      = aws_vpc.main.id

  # MySQL from VPC
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # PostgreSQL from VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project-bedrock-db-sg"
  }
}

# Dynamic DB passwords (excluding special characters to prevent DSN parsing errors)
resource "random_password" "mysql_password" {
  length           = 16
  special          = false
}

resource "random_password" "postgres_password" {
  length           = 16
  special          = false
}

# RDS MySQL Instance (Catalog Service)
resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  max_allocated_storage  = 50
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t4g.micro"
  db_name                = "catalog"
  username               = var.db_username
  password               = random_password.mysql_password.result
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  apply_immediately      = true

  tags = {
    Name = "project-bedrock-mysql"
  }
}

# RDS PostgreSQL Instance (Orders Service)
resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  max_allocated_storage  = 50
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t4g.micro"
  db_name                = "orders"
  username               = var.db_username
  password               = random_password.postgres_password.result
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  apply_immediately      = true

  tags = {
    Name = "project-bedrock-postgres"
  }
}

# DynamoDB Table (Carts Service)
resource "aws_dynamodb_table" "carts" {
  name           = "carts"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "customerId"
    type = "S"
  }

  global_secondary_index {
    name               = "idx_global_customerId"
    hash_key           = "customerId"
    projection_type    = "ALL"
    read_capacity      = 5
    write_capacity     = 5
  }

  tags = {
    Name = "project-bedrock-carts-dynamodb"
  }
}

# Store database credentials in SSM Parameter Store
resource "aws_ssm_parameter" "mysql_endpoint" {
  name        = "/retail-app/db/mysql_endpoint"
  description = "MySQL DB Endpoint URL"
  type        = "String"
  value       = aws_db_instance.mysql.endpoint
  overwrite   = true
}

resource "aws_ssm_parameter" "mysql_password" {
  name        = "/retail-app/db/mysql_password"
  description = "MySQL Master Password"
  type        = "SecureString"
  value       = random_password.mysql_password.result
  overwrite   = true
}

resource "aws_ssm_parameter" "postgres_endpoint" {
  name        = "/retail-app/db/postgres_endpoint"
  description = "PostgreSQL DB Endpoint URL"
  type        = "String"
  value       = aws_db_instance.postgres.endpoint
  overwrite   = true
}

resource "aws_ssm_parameter" "postgres_password" {
  name        = "/retail-app/db/postgres_password"
  description = "PostgreSQL Master Password"
  type        = "SecureString"
  value       = random_password.postgres_password.result
  overwrite   = true
}

# Create Kubernetes Namespace for the Retail Store App
resource "kubernetes_namespace" "retail" {
  metadata {
    name = var.namespace
  }
}

# Deploy MySQL Database Secret directly in EKS namespace
resource "kubernetes_secret" "catalog_db" {
  metadata {
    name      = "catalog-db"
    namespace = kubernetes_namespace.retail.metadata[0].name
  }

  data = {
    RETAIL_CATALOG_PERSISTENCE_USER     = var.db_username
    RETAIL_CATALOG_PERSISTENCE_PASSWORD = random_password.mysql_password.result
  }

  type = "Opaque"
}

# Deploy PostgreSQL Database Secret directly in EKS namespace
resource "kubernetes_secret" "orders_db" {
  metadata {
    name      = "orders-db"
    namespace = kubernetes_namespace.retail.metadata[0].name
  }

  data = {
    RETAIL_ORDERS_PERSISTENCE_USERNAME = var.db_username
    RETAIL_ORDERS_PERSISTENCE_PASSWORD = random_password.postgres_password.result
  }

  type = "Opaque"
}

# Dynamically generate values.yaml for the Helm Chart deployment
resource "local_file" "helm_values" {
  filename = "${path.module}/../kubernetes/retail-store-sample-app/values.yaml"
  content  = <<EOF
# Global settings
namespace: ${var.namespace}

# Images configuration
images:
  catalog: "public.ecr.aws/aws-containers/retail-store-sample-catalog:1.6.1"
  carts: "public.ecr.aws/aws-containers/retail-store-sample-cart:1.6.1"
  orders: "public.ecr.aws/aws-containers/retail-store-sample-orders:1.6.1"
  checkout: "public.ecr.aws/aws-containers/retail-store-sample-checkout:1.6.1"
  ui: "public.ecr.aws/aws-containers/retail-store-sample-ui:1.6.1"
  assets: "public.ecr.aws/aws-containers/retail-store-sample-assets:0.4.0"

# Database Configuration (Managed RDS MySQL)
mysql:
  endpoint: "${aws_db_instance.mysql.endpoint}"
  database: "${aws_db_instance.mysql.db_name}"
  username: "${var.db_username}"

# Database Configuration (Managed RDS PostgreSQL)
postgres:
  endpoint: "${aws_db_instance.postgres.endpoint}"
  database: "${aws_db_instance.postgres.db_name}"
  username: "${var.db_username}"

# DynamoDB Configuration (Managed DynamoDB Carts Table)
dynamodb:
  table: "${aws_dynamodb_table.carts.name}"
  region: "${var.aws_region}"
  roleArn: "${aws_iam_role.carts_dynamodb.arn}"
EOF
}


