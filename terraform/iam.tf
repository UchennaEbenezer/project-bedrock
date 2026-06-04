# Developer IAM User
resource "aws_iam_user" "dev_user" {
  name = "bedrock-dev-view"

  tags = {
    Name = "bedrock-dev-view"
  }
}

# Attach standard ReadOnlyAccess managed policy
resource "aws_iam_user_policy_attachment" "dev_readonly" {
  user       = aws_iam_user.dev_user.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Create inline policy for PutObject on assets bucket
resource "aws_iam_user_policy" "dev_s3_put" {
  name = "bedrock-dev-s3-put-policy"
  user = aws_iam_user.dev_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.assets.arn}/*"
      }
    ]
  })
}

# Generate Access Key for Developer user
resource "aws_iam_access_key" "dev_key" {
  user = aws_iam_user.dev_user.name
}
