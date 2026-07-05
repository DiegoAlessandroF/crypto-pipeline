terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "raw_data" {
  bucket = "crypto-pipeline-raw-${data.aws_caller_identity.current.account_id}"

  tags = {
    Project     = "crypto-pipeline"
    Environment = "dev"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_versioning" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "crypto-pipeline-key"
  public_key = file("/home/diego/.ssh/crypto-pipeline-key.pub")

  tags = {
    Project = "crypto-pipeline"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "crypto-pipeline-sg"
  description = "Security group para EC2 do crypto-pipeline"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["177.192.5.241/32"]
  }

  ingress {
    description = "Airflow"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["177.192.5.241/32"]
  }

  ingress {
    description = "Superset"
    from_port   = 8088
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = ["177.192.5.241/32"]
  }

  ingress {
    description = "Kafka"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["177.192.5.241/32"]
  }

  egress {
    description = "Permite todo trafego de saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "crypto-pipeline"
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "crypto-pipeline-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "crypto-pipeline"
  }
}

resource "aws_iam_role_policy" "ec2_permissions" {
  name = "crypto-pipeline-ec2-permissions"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.raw_data.arn,
          "${aws_s3_bucket.raw_data.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "redshift-serverless:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "crypto-pipeline-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "crypto_pipeline" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name    = "crypto-pipeline-ec2"
    Project = "crypto-pipeline"
  }
}

resource "aws_eip" "crypto_pipeline" {
  instance = aws_instance.crypto_pipeline.id
  domain   = "vpc"

  tags = {
    Name    = "crypto-pipeline-eip"
    Project = "crypto-pipeline"
  }
}
