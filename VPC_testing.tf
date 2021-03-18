
provider "aws"{
    region= "us-west-2"
    access_key="AKIAWLMDXOSGHL5AYCGN"
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

resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.main.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.testing.id]

}

resource "aws_eip" "eip_pub" {
  vpc                       = true
  network_interface         = aws_network_interface.test.id
  associate_with_private_ip = "10.0.1.50" 
  depends_on                = [aws_internet_gateway.IGW]
}
resource "aws_eip_association" "eip_public" {
  instance_id   = aws_instance.myec.id
  allocation_id = aws_eip.eip_pub.id
}
resource "aws_instance" "myec" {
  ami           = "ami-0ca5c3bd5a268e7db"
  instance_type = "t2.micro"
  # security_groups= [aws_security_group.testing.id]
  # vpc_security_group_ids = [aws_security_group.testing.id]

  tags = {
    Name = "Pubinstance"
  }

  # subnet_id = aws_subnet.main.id
  instance_initiated_shutdown_behavior = "terminate"
  disable_api_termination = false
  availability_zone ="us-west-2a"
  key_name = "access-key"
  network_interface {

    device_index = 0
    network_interface_id = aws_network_interface.test.id
  }
  user_data = <<-EOF
             #!/bin/bash
             sudo apt update -y
             sudo apt install apache2 -y
             sudo systemctl start apache2
             sudo bash -c 'echo this is your first web server > /var/www/html/index.html'
             EOF 
}

resource "aws_security_group" "testing" {
  name        = "test"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTP"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]

  }
  ingress {
    description = "HTTPS"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]

  }
  ingress {
    description = "SSH"
    from_port         = 2
    to_port           = 2
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]

  }
  egress {
    description = "TLS from VPC"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]

  }

  tags = {
    Name = "allow_tls"
  }
}
