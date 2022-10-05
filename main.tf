terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "aws-bucket-1" {
  bucket = "cttc-tf-app-jar-bucket"

  tags = {
    Name = "cttc-tf-app-jar-bucket"
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.aws-bucket-1.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetObjectVersion"
    ]

    resources = [
      aws_s3_bucket.aws-bucket-1.arn,
      "${aws_s3_bucket.aws-bucket-1.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_object" "app-jar" {
  bucket = "cttc-tf-app-jar-bucket"
  key    = "cttc-0.0.1-SNAPSHOT.jar"
  source = "/builds/cicd2022-09/dave.-schick/cttc_pipeline/target/cttc-0.0.1-SNAPSHOT.jar"
  depends_on = [
    aws_s3_bucket.aws-bucket-1
  ]
}

resource "aws_default_vpc" "default-vpc" {
  tags = {
    Name = "CTTC Default VPC"
  }
}


resource "aws_instance" "app_server" {
  ami                  = "ami-026b57f3c383c2eec"
  instance_type        = "t2.micro"
  security_groups      = ["cttc_allow_tcp_8080", "cttc_allow_ssh_22"]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name             = "dave-schick-ssh-key-new"
  user_data            = <<EOF
    #!/bin/bash
    echo "Update dependencies"
    sudo yum update -y
    echo "Install Java 11"
    sudo yum install -y java-11-amazon-corretto-headless    
    echo "Pull spring boot app from S3 bucket"
    aws s3api get-object --bucket cttc-tf-app-jar-bucket --key cttc-0.0.1-SNAPSHOT.jar cttc-0.0.1-SNAPSHOT.jar
    echo "run the spring boot app"
    sudo java -jar cttc-0.0.1-SNAPSHOT.jar
    echo "spring boot app should be up and running"
    EOF
  tags = {
    Name = "cttc-app-server"
  }
}

resource "aws_security_group" "cttc_allow_TCP_8080" {
  name        = "cttc_allow_tcp_8080"
  description = "Allow TCP inbound and outbound traffic"

  ingress {
    description = "TCP from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cttc_allow_tcp_8080"
  }
}

resource "aws_security_group" "allow_SSH_22" {
  name        = "cttc_allow_ssh_22"
  description = "Allow SSH inbound and outbound traffic"

  ingress {
    description = "SSH from LocalVPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cttc_allow_tcp_8080"
  }
}


resource "aws_iam_policy" "ec2_policy" {
  name        = "cttc-ec2-policy"
  path        = "/"
  description = "policy to allow ec2 instance to access S3 bucket"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::cttc-tf-app-jar-bucket/*",
          "arn:aws:s3:::cttc-tf-app-jar-bucket"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "s3:ListAllMyBuckets",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "cttc_ec2_role"
  assume_role_policy = jsonencode({ Version = "2012-10-17"
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
}

resource "aws_iam_policy_attachment" "ec2_policy_role" {
  name       = "cttc-ec2-attachment"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "cttc-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
