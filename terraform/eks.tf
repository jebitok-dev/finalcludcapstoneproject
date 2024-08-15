resource "aws_iam_role" "eks_cluster" {
    name = "eksClusterRole"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "eks.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role       = "aws_iam_role.eks_nodes.name"
}

resource "aws_iam_role_policy_attachment" "eks_container_registry" {
    policy_arn = "arn:aws:iam::aws:policy/AWSEC2ContainerRegistryReadOnly"
    role       = aws_iam_role.eks_nodes.name
}

module "eks" {
    source  = "terraform-aws-modules/eks/aws"
    version = "~> 18.0"

    cluster_name    = var.cluster_name
    cluster_version = "1.24"

    vpc_id     = aws_vpc.main.id
    subnet_ids = aws_subnet.public[*].id

    cluster_security_group_id = aws_security_group.eks_cluster.id
    cluster_iam_role_name = aws_iam_role.eks_cluster.name

    eks_managed_node_groups_defaults = {
        ami_type = "AL2_x86_64"
        instance_types = ["t3.medium"]
    }

    eks_managed_node_groups = {
        socks-shop = {
            min_size     = 2
            max_size     = 5
            desired_size = 2

            iam_role_additional_policies =[
                "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
                "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
                "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
            ]
        }
    }

    tags = {
        Environment = "production"
        Application = "socks-shop"
    }
}

output "cluster_endpoint" {
    description = "Endpoint for EKS control panel"
    value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
    description = "Security group ids attached to the cluster control panel"
    value       = module.eks.cluster_security_group_id
}

output "cluster_name" {
    description = "Kubernetes Cluster Name"
    value       = var.cluster_name
}