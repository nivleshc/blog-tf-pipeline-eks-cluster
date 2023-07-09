resource "kubernetes_service_account_v1" "aws_load_balancer_controller" {
  metadata {
    labels = {
      "app.kubernetes.io/name" = local.ingress_alb_controller.name
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
    }

    name      = local.ingress_alb_controller.name
    namespace = local.ingress_alb_controller.namespace
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = local.ingress_alb_controller.name
  repository = local.ingress_alb_controller.helm.repository
  chart      = local.ingress_alb_controller.helm.chart.name
  version    = local.ingress_alb_controller.helm.chart.version
  namespace  = local.ingress_alb_controller.namespace

  set {
    name  = "clusterName"
    value = local.ingress_alb_controller.helm.chart.values.clusterName
  }

  set {
    name  = "serviceAccount.create"
    value = local.ingress_alb_controller.helm.chart.values.serviceAccount_create
  }

  set {
    name  = "serviceAccount.name"
    value = local.ingress_alb_controller.helm.chart.values.serviceAccount_name
  }

  set {
    name  = "vpcId"
    value = local.ingress_alb_controller.helm.chart.values.vpcId
  }

  set {
    name  = "region"
    value = local.ingress_alb_controller.helm.chart.values.region
  }

  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_iam_role.aws_load_balancer_controller
  ]
}