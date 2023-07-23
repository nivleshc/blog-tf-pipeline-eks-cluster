resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = local.prometheus.namespace
  }

  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}

resource "helm_release" "prometheus" {
  name       = local.prometheus.name
  repository = local.prometheus.helm.repository
  chart      = local.prometheus.helm.chart.name
  version    = local.prometheus.helm.chart.version

  namespace = kubernetes_namespace.prometheus.id

  values = ["${file(local.prometheus.helm.values_filename)}"]

  depends_on = [
    aws_eks_cluster.eks_cluster,
    kubernetes_namespace.prometheus,
    aws_eks_addon.aws_ebs_csi_driver
  ]
}