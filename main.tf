provider "aws" {
    region = "us-west-2"
}

resource "aws-rpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "socks-shop-vpc"
    }
}

resource "aws-subnet" "public" {
    count = 2
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.${count.index}.0/24"
    availability_zone = data.aws_availability_zones.available.names[count.index]

    tags = {
        Name = "socks-shop-public-subnet-${count.index + 1}"
    }
}

data "aws_availability_zones" "available" {}