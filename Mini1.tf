#state terraform provider and use programmatic access
provider "aws" {
region = "eu-west-1"
}

#Create VPC
resource "aws_vpc" "Cloud_vpc" {
cidr_block = "10.0.0.0/16"
instance_tenancy = "default"

tags = {
Name = "Cloud_vpc"
}
}

#Create 2 subnets
#first one is public subnets
resource "aws_subnet" "Public_SN_Cloud"{
vpc_id = aws_vpc.Cloud_vpc.id
cidr_block = "10.0.1.0/24"
tags = {
Name = "Public_SN_Cloud"
}
}

#second one is private subnet
resource "aws_subnet" "Private_SN_Cloud" {
vpc_id = aws_vpc.Cloud_vpc.id
cidr_block = "10.0.2.0/24"
tags = {
Name = "Private_SN_Cloud"
}
}

#Create Internet Gateway
resource "aws_internet_gateway" "Cloud_igw" {
vpc_id = aws_vpc.Cloud_vpc.id
tags = {
Name = "Cloud_igw"
}
}

# create elastic ip
resource "aws_eip" "Cloud_NG" {
  vpc = true
}

#Create Nat Gateway and associate it with the Public Subnet
resource "aws_nat_gateway" "Cloud_NG" {
  allocation_id = aws_eip.Cloud_NG.id
subnet_id = aws_subnet.Public_SN_Team_3.id
tags = {
Name = "Cloud_NG"
}
}

#Create 2 Route Table
#public RT
resource "aws_route_table" "Cloud_FRT" {
vpc_id = aws_vpc.Cloud_vpc.id

route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.Cloud_igw.id
}

tags = {
Name = "Cloud_FRT"
}
}

#Private RT
resource "aws_route_table" "Cloud_PRT" {
vpc_id = aws_vpc.Cloud_vpc.id

route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.Cloud_igw.id
}

tags = {
Name = "Cloud_BRT"
}
}

#create security group
#create 2 security groups
#frontend SG
resource "aws_default_security_group" "Cloud_FSG" {
  vpc_id = aws_vpc.Cloud_vpc.id
  tags = {
Name = "Cloud_FSG"
}
  ingress {
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
        to_port   = 22
  }
ingress {
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 80
    to_port   = 80
  }
  ingress {
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 443
    to_port   = 443
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
}
#backend SG
resource "aws_security_group" "Cloud_BSG" {
  vpc_id = aws_vpc.Cloud_vpc.id
  tags = {
Name = "Cloud_BSG"
}
  ingress {
    protocol  = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
    from_port = 3306
    to_port   = 3306
  }
  ingress {
    protocol  = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
    from_port = 22
    to_port   = 22
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
}
}
#s3 bucket section

resource "aws_s3_bucket" "cloud-media" {
  bucket = "cloud-media"
  acl    = "public-read"

}


resource "aws_s3_bucket" "cloud-web-backup" {
  bucket = "cloud-web-backup"
  acl    = "private"
}


 resource "aws_s3_bucket_policy" "cloud-media-policy" {
  bucket = "cloud-media"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "cloud-media-policy",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
    "Principal": "*",
      "Action": [
          "s3:GetObject"
          ],
      "Resource":[
          "arn:aws:s3:::cloud-media/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role" "cloud_iam_role" {
  name = "cloud_administrator"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    tag-key = "major_admin"
  }
}