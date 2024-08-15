variable "region" {
    description = "AWS region"
    type        = string
    default     = "us-east-1"
}

variable "vpc_cidr" {
    description = "CIDR block for VPC"
    default     = "10.0.0.0/16"
}

variable "cluster_name" {
    description = "Name of the EKS cluster"
    default     = "socks-shop-cluster"
}

variable "aws_access_key" {
    description = "AWS access key"
    type        = string
}

variable "aws_secret_key" {
    description = "AWS secret key"
    type        = string
}