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
    instance_type = "t3.medium"
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

  amazoneks_ebs_csi_controller = {
    service_account_name = "ebs-csi-controller-sa"
    namespace            = "kube-system"

    role_name_suffix       = "AmazonEKS_EBS_CSI_DriverRole"
    aws_managed_policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"

    addon_name = "aws-ebs-csi-driver"
  }

  prometheus = {
    name      = "prometheus"
    namespace = "${var.env}-prometheus"

    helm = {
      repository = "https://prometheus-community.github.io/helm-charts"

      chart = {
        name    = "prometheus"
        version = "23.1.0"
      }

      values_filename = "values/prometheus.yaml"
    }
  }

  grafana = {
    name      = "grafana"
    namespace = "${var.env}-grafana"

    service_port = 3000

    helm = {
      repository = "https://grafana.github.io/helm-charts"

      chart = {
        name    = "grafana"
        version = "6.58.4"
      }

      values_filename = "values/grafana.tftpl"
    }

    admin_credentials = {
      username_ssm_parameter_path = "/${var.env}/grafana/admin/username"
      password_ssm_parameter_path = "/${var.env}/grafana/admin/password"
    }

    ingress = {
      annotations = {
        scheme      = "internet-facing"
        target_type = "instance"
      }
      class_name = "alb"
      rule = {
        http = {
          path = {
            path      = "/"
            path_type = "Prefix"
          }
        }
      }
    }
  }
}