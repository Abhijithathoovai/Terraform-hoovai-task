resource "aws_iam_role" "trust-ec2" {
  name = "ec2-role-tf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "trust-ec2"
  }
}

resource "aws_iam_role" "trust-codedeploy" {
  name = "codedeploy-role-tf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "trust-codedeploy"
  }
}

resource "aws_iam_role" "trust-pipeline" {
  name = "codepipeline-role-tf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "trust-codepipeline"
  }
}

resource "aws_iam_role_policy" "allow_codestar_connection" {
  name = "AllowCodeStarConnection"
  role = aws_iam_role.trust-pipeline.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "codestar-connections:UseConnection"
        ],
        Resource = "${aws_codestarconnections_connection.codestar.arn}"
      }
    ]
  })
}

data "aws_iam_policy" "ec2_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

data "aws_iam_policy" "ec2_policy2" {
  arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
}
data "aws_iam_policy" "codedeploy_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

data "aws_iam_policy" "codepipeline_policy" {
  arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}


resource "aws_iam_role_policy_attachment" "ec2-tf-attach" {
  role       = aws_iam_role.trust-ec2.name
  policy_arn = data.aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2-tf-attach2" {
  role       = aws_iam_role.trust-ec2.name
  policy_arn = data.aws_iam_policy.ec2_policy2.arn
}

resource "aws_iam_role_policy_attachment" "codedeploy-tf-attach" {
  role       = aws_iam_role.trust-codedeploy.name
  policy_arn = data.aws_iam_policy.codedeploy_policy.arn
}

resource "aws_iam_role_policy_attachment" "codepipeline-tf-attach" {
  role       = aws_iam_role.trust-pipeline.name
  policy_arn = aws_iam_policy.cd-pipeline-policy.arn
}



resource "aws_iam_instance_profile" "ec2_tf_profile" {
  name = "ec2_profile"
  role = aws_iam_role.trust-ec2.name
}