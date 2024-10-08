provider "aws" {
    region     = var.region
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}

resource "aws_vpc" "main" {
    cidr_block           = var.vpc_cidr
    enable_dns_hostnames = true

    tags = {
      Name = "socks-shop-vpc"
    }
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "socks-shop-igw"
    }
}

resource "aws_subnet" "public" {
    count                   = 2
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.${count.index}.0/24"
    availability_zone       = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = true

    tags = {
        Name = "socks-shop-public-subnet-${count.index + 1}"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "socks-shops-public-rt"
    }
}

resource "aws_route_table_association" "public" {
    count          = 2
    subnet_id      = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

data "aws_availability_zones" "available" {}