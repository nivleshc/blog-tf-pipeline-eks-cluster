resource "aws_eks_cluster" "eks_cluster" {
  name     = local.eks.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = local.eks.version

  vpc_config {
    subnet_ids = [
      aws_subnet.eks_cluster_vpc_private_subnets[0].id,
      aws_subnet.eks_cluster_vpc_private_subnets[1].id
    ]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = local.eks_node_group.name
  node_role_arn   = aws_iam_role.eks_cluster_node_group.arn
  subnet_ids      = aws_subnet.eks_cluster_vpc_private_subnets[*].id
  capacity_type   = local.eks_node_group.capacity_type
  instance_types  = [local.eks_node_group.instance_type]

  scaling_config {
    desired_size = local.eks_node_group.desired_size
    max_size     = local.eks_node_group.max_size
    min_size     = local.eks_node_group.min_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_cluster_node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_cluster_node_group_AmazonEC2ContainerRegistryReadOnly,
    aws_route_table_association.public_rt_association,
  ]
}

data "tls_certificate" "eks_cluster" {
  url = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "eks_cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}

output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "eks_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_certificate_authority" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}