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
