provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "iaac-backend-uat"
    key = "ciremote.tfstate"
    region = "us-east-1"
  }
}

resource "aws_vpc" "ci_vpc" {
    cidr_block = "20.0.0.0/24"
    enable_dns_hostnames = true
    enable_dns_support = true
  
}

resource "aws_subnet" "ci_subnet" {
  vpc_id = aws_vpc.ci_vpc.id
  cidr_block = "20.0.0.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_internet_gateway" "ci_igw" {
    vpc_id = aws_vpc.ci_vpc.id
  
}

resource "aws_route_table" "ci_route_table" {
    vpc_id = aws_vpc.ci_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.ci_igw.id
    }
  
}

resource "aws_route_table_association" "ci_subnet_association" {
  subnet_id = aws_subnet.ci_subnet.id
  route_table_id = aws_route_table.ci_route_table.id
}

resource "aws_security_group" "ci_sg" {
    vpc_id = aws_vpc.ci_vpc.id

 ingress {
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "jenkins_srv" {
    ami = "ami-02d7fd1c2af6eead0"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.ci_subnet.id
    associate_public_ip_address = true    
    security_groups = [ aws_security_group.ci_sg.id ]
    tags = {Name = "jenkins-srv"}
    

user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y java-1.8.0
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo yum install -y jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    EOF
}