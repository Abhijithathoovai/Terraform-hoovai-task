resource "aws_iam_policy" "cd-pipeline-policy" {
  name        = "cdp"
  description = "Policy for CodePipeline to have full access to EC2, S3, CodeDeploy, and CodeStar"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EC2FullAccess"
        Effect   = "Allow"
        Action   = "ec2:*"
        Resource = "*"
      },
      {
        Sid      = "S3FullAccess"
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "*"
      },
      {
        Sid      = "CodeDeployFullAccess"
        Effect   = "Allow"
        Action   = "codedeploy:*"
        Resource = "*"
      },
      {
        Sid      = "CodeStarFullAccess"
        Effect   = "Allow"
        Action   = "codestar:*"
        Resource = "*"
      },
      {
        Sid      = "PassRoleForServices"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringLike = {
            "iam:PassedToService" = [
              "codedeploy.amazonaws.com",
              "codepipeline.amazonaws.com",
              "ec2.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}
