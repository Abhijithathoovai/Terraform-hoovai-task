
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20250516*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_key_pair" "deployer" {
  key_name   = "tfkey"
  public_key = file("tfkey.pub")
}

resource "aws_instance" "tf-web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3a.micro"
  key_name               = aws_key_pair.deployer.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_tf-cd-profile.name
  vpc_security_group_ids = [aws_security_group.tf_nsg.id]
  availability_zone      = "us-east-1a"

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt upgrade -y
              sudo apt install apache2 -y
              cd /
              cd /var/www/html
              rm -rf index.html
              sudo apt install wget -y
              sudo systemctl start apache2
              sudo systemctl enable apache2
              sudo apt install ruby -y
              wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
              chmod +x install
              sudo ./install auto
              sudo systemctl start codedeploy-agent
              sudo systemctl enable codedeploy-agent
              EOF


  tags = {
    Name = "tf_instance"
  }
}

resource "aws_s3_bucket" "tf-codepipeline_bucket" {
  bucket        = "tf-cd-pipeline-s3-1912-abhi-hoovai-linux"
  force_destroy = true

  tags = {
    Name = "tf-cd-pipeline"
  }
}

resource "aws_codedeploy_app" "cdapp" {
  name             = "tfcdapp"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "cdgroup" {
  app_name              = aws_codedeploy_app.cdapp.name
  deployment_group_name = "tfcdgroup"
  service_role_arn      = aws_iam_role.trust-codedeploy.arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "tf_instance"
    }
  }
}

resource "aws_codestarconnections_connection" "codestar" {
  name          = "tf-codestar-hoovai"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "cdpipeline" {
  name     = "tf-cd-pipeline"
  role_arn = aws_iam_role.trust-pipeline.arn

  artifact_store {
    location = aws_s3_bucket.tf-codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.codestar.arn
        FullRepositoryId = "Abhijithathoovai/codedeploytest"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy_to_EC2"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.cdapp.name
        DeploymentGroupName = aws_codedeploy_deployment_group.cdgroup.deployment_group_name
      }
    }
  }
}