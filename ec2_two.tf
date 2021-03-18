
provider "aws"{
    region= "us-west-2"
    access_key="AKIAWLMDXOSGM46LG4FB"
    secret_key="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"
}
resource "aws_vpc" "vpc" {
  cidr_block                       = "10.0.0.0/16"
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = false
  tags = {
    Name = "MYvpc"
  }
}
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch= true
  tags = {
    Name = "new"
  }
}
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "myigw"
  }
}
resource "aws_route_table" "pubroute" {
  vpc_id =  aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
  tags = {
    Name = "main"
  }
}
resource "aws_route_table_association" "pub" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.pubroute.id
}

resource "aws_instance" "myec" {
  ami           = "ami-00f9f4069d04c0c6e"
  instance_type = "t2.micro"
  # security_groups= [aws_security_group.testing.id]
  vpc_security_group_ids = [aws_security_group.testing.id]
  tags = {
    Name = "Pubinstance"
  }

  subnet_id = aws_subnet.main.id
  instance_initiated_shutdown_behavior = "terminate"
  disable_api_termination = false
  availability_zone ="us-west-2a"
}

resource "aws_security_group" "testing" {
  name        = "test"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "TLS from VPC"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = [aws_vpc.vpc.cidr_block]
  }

  tags = {
    Name = "mysg"
  }
}
output "ec2_pub_ip" {
  value = aws_instance.myec.public_ip
}
output "ec2_availabilityzone" {
  value = aws_instance.myec.availability_zone
}
output "ec2_instance_type" {
  value = aws_instance.myec.instance_type
}
