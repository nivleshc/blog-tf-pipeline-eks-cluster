locals {
  vpc = {
    name                = "${var.env}-eks-vpc"
    tenancy             = "default"
    cidr                = "10.0.0.0/16"
    num_public_subnets  = 2
    num_private_subnets = 2
  }

  eks = {
    cluster_name  = "${var.env}-eks-cluster"
    version       = "1.25"
    iam_role_name = "${var.env}-eks-cluster-iam-role"
  }

  eks_cluster_sg_name = "${local.eks.cluster_name}-sg"

  eks_node_group = {
    name          = "${local.eks.cluster_name}-node-group"
    iam_role_name = "${local.eks.cluster_name}-node-group-role"
    instance_type = "t3.small"
    capacity_type = "ON_DEMAND"
    desired_size  = 1
    max_size      = 2
    min_size      = 1
  }

  eks_node_group_sg_name = "${local.eks_node_group.name}-sg"

  ingress_alb_controller = {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    helm = {
      repository = "https://aws.github.io/eks-charts"
      chart = {
        name    = "aws-load-balancer-controller"
        version = "1.5.4"

        values = {
          clusterName           = aws_eks_cluster.eks_cluster.name
          serviceAccount_name   = "aws-load-balancer-controller"
          serviceAccount_create = "false"
          vpcId                 = aws_vpc.eks_cluster_vpc.id
          region                = "ap-southeast-2"
        }
      }
    }
  }
}