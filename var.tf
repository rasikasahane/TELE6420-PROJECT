# AWS Region and Profile
variable "aws_region" {
  description = "The AWS region to create resources in"
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "CLI profile"
  default     = "tele6420"
}

# VPC CIDR Block
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name of the VPC"
  default     = "tele6420-vpc"
}

# Public Subnet CIDRs
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

# Private Subnet CIDRs##
variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

# Availability Zones
variable "availability_zones" {
  description = "List of availability zones to use"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Application port

variable "app_port" {
  description = "Application Port"
  default     = "8080"
}

variable "ami_id" {
  description = "ID of the image created"
  default     = "ami-0218fc89812143a7e"
}

variable "db_username" {
  description = "Username for DB"
  default     = "tele6420"
}

variable "db_name" {
  description = "DB Name"
  default     = "tele6420"
}

variable "db_password" {
  description = "DB Password"
  default     = "Connectt0DB!23"
}

variable "route53_zone_id" {
  description = "Route53 Zone ID for dev"
  type        = string
  default     = "Z0810453YULKMYXTND62"
}

variable "record_name" {
  description = "A Record name"
  type        = string
  default     = "tele6420.net-bound.com"
}


variable "db_port" {
  description = "DB PORT"
  default     = "5432"
}
