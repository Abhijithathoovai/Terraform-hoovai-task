output "ami_id" {
  description = "The AMI ID used for the EC2 instance"
  value       = data.aws_ami.ubuntu.id
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.tf-web.public_ip
}
