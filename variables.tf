variable "aws_region" {
  default = "us-west-2"
}

variable "student_email" {
  description = "Email for SNS alerts"
  type        = string
}

variable "instance_type" {
  description = "Initial EC2 instance size"
  default     = "t2.micro"
}

variable "ami" {
  description = "Amazon Linux AMI"
  default     = "ami-0c02fb55956c7d316"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet1_cidr" {
  default = "10.0.1.0/24"
}

variable "subnet2_cidr" {
  default = "10.0.2.0/24"
}