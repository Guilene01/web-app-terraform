terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

############################
# GET LATEST AMAZON LINUX
############################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

############################
# VPC
############################

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "student-vpc"
  }
}

############################
# INTERNET GATEWAY
############################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "student-igw"
  }
}

############################
# SUBNETS
############################

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet1_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "student-subnet-1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet2_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "student-subnet-2"
  }
}

############################
# ROUTE TABLE
############################

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "student-public-rt"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

############################
# SECURITY GROUPS
############################

resource "aws_security_group" "alb_sg" {
  name        = "student-alb-sg"
  description = "Allow HTTP from internet to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "student-alb-sg"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "student-web-sg"
  description = "Allow HTTP only from ALB and SSH for troubleshooting"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "SSH for lab troubleshooting"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "student-web-sg"
  }
}

############################
# EC2 WEB SERVERS
############################

resource "aws_instance" "web" {
  count         = 2
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id = element([
    aws_subnet.subnet1.id,
    aws_subnet.subnet2.id
  ], count.index)

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "Student-Web-${count.index}"
  }

  user_data = <<EOF
#!/bin/bash
set -eux

dnf update -y
dnf install -y httpd stress-ng

systemctl enable httpd
systemctl start httpd

echo "<h1>Server ${count.index}</h1><p>Application is running</p>" > /var/www/html/index.html

# Simulate both failures on server 0
if [ ${count.index} -eq 0 ]; then
  nohup bash -c '
    sleep 120
    stress-ng --cpu 2 --timeout 300 &
    sleep 120
    systemctl stop httpd
  ' >/var/log/failure-simulation.log 2>&1 &
fi

EOF
}

############################
# APPLICATION LOAD BALANCER
############################

resource "aws_lb" "web_alb" {
  name               = "student-web-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.subnet1.id,
    aws_subnet.subnet2.id
  ]

  tags = {
    Name = "student-web-alb"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "student-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "student-web-tg"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "web_attach" {
  count = 2

  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

############################
# SNS ALERTS
############################

resource "aws_sns_topic" "alerts" {
  name = "student-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.student_email
}

############################
# CLOUDWATCH CPU ALARM
############################

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "web-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"

  period    = 60
  statistic = "Average"

  threshold = 40

  dimensions = {
    InstanceId = aws_instance.web[0].id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

############################
# CLOUDWATCH ALB UNHEALTHY TARGET ALARM
############################

resource "aws_cloudwatch_metric_alarm" "unhealthy_target" {
  alarm_name          = "web-unhealthy-target"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1

  metric_name = "UnHealthyHostCount"
  namespace   = "AWS/ApplicationELB"

  period    = 60
  statistic = "Maximum"

  threshold = 0

  dimensions = {
    LoadBalancer = aws_lb.web_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.web_tg.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}