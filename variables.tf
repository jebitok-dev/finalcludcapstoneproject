variable "region" {
    description = "AWS region"
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