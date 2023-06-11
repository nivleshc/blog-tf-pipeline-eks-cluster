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

output "eks_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}