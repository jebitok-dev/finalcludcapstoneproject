resource "aws_eks_cluster" "main" {
    name = "socks-shop-cluster"
    role_arn = aws_iam_role.eks_cluster.role_arn

    vps_config {
        subnet_ids = aws_subnet.public[*].id
    }

    depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

resource "aws_iam_role" "eks_cluster" {
    name = "eks_cluster-role"

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
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
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

