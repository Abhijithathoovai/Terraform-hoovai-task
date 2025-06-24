data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250610*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_key_pair" "deployer" {
  key_name   = "tf-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAYHjPdOzoVU/OjivX6Srlm1UShQSfGPLWSG0rvglUWV azuread\\abhijithdhanan@DESKTOP-C9A46FA"
}

resource "aws_instance" "tf-web" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t3a.micro"
  key_name             = aws_key_pair.deployer.key_name
  availability_zone    = "us-east-1a"
  iam_instance_profile = aws_iam_instance_profile.ec2_tf_profile.name
  vpc_security_group_ids = [aws_security_group.tf_nsg.id]



  provisioner "file" {
    source      = "user_data.sh"
    destination = "/tmp/user_data.sh"
  }

connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = file("tfkey")
    host     = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/user_data.sh",
      "sudo /tmp/user_data.sh"
      
    ]
  }
  
 
  tags = {
    Name = "tf_instance"
  
}
}

resource "aws_codedeploy_app" "cdapp" {
  compute_platform = "Server"
  name             = "tfcdapp"

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

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket        = "tf-cd-pipeline-s3-1912"
  force_destroy = true

  tags = {
    Name = "tf-cd-pipeline"
  }
}

resource "aws_codestarconnections_connection" "codestar" {
  name          = "tf-codestar"
  provider_type = "GitHub"
  }

resource "aws_codepipeline" "cdpipeline" {
  name     = "tf-cd-pipeline"
  role_arn = aws_iam_role.trust-pipeline.arn

    artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
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
      name            = "Deploy_to_ec2"
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
