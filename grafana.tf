resource "kubernetes_namespace" "grafana" {
  metadata {
    name = local.grafana.namespace
  }

  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}

resource "helm_release" "grafana" {
  name       = local.grafana.name
  repository = local.grafana.helm.repository
  chart      = local.grafana.helm.chart.name
  version    = local.grafana.helm.chart.version

  namespace = kubernetes_namespace.grafana.id

  values = [
    templatefile(local.grafana.helm.values_filename, { service_port = local.grafana.service_port, namespace = "${kubernetes_namespace.prometheus.id}", grafana_dashboards = fileset("${path.module}/grafana_dashboards/", "*.json"), module_path = "${path.module}" })
  ]

  depends_on = [
    aws_eks_cluster.eks_cluster,
    kubernetes_namespace.grafana,
    helm_release.prometheus
  ]
}

data "kubernetes_service" "grafana" {
  metadata {
    name = local.grafana.name
  }

  depends_on = [
    helm_release.grafana
  ]
}

resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = local.grafana.name
    namespace = kubernetes_namespace.grafana.id
    annotations = {
      "alb.ingress.kubernetes.io/scheme"      = local.grafana.ingress.annotations.scheme
      "alb.ingress.kubernetes.io/target-type" = local.grafana.ingress.annotations.target_type
    }
    labels = {
      "app.kubernetes.io/name" = local.grafana.name
    }
  }
  spec {
    ingress_class_name = local.grafana.ingress.class_name
    rule {
      http {
        path {
          path = local.grafana.ingress.rule.http.path.path
          backend {
            service {
              name = local.grafana.name
              port {
                number = local.grafana.service_port
              }
            }
          }
          path_type = local.grafana.ingress.rule.http.path.path_type
        }
      }
    }
  }

  depends_on = [
    aws_eks_cluster.eks_cluster,
    kubernetes_namespace.grafana,
    helm_release.grafana
  ]
}

# store the grafana admin password in AWS SSM Parameter Store
data "kubernetes_secret_v1" "grafana_admin_credentials" {
  metadata {
    name      = local.grafana.name
    namespace = kubernetes_namespace.grafana.id
  }

  binary_data = {
    "admin-password" = ""
    "admin-user"     = ""
    "ldap-toml"      = ""
  }

  depends_on = [
    helm_release.grafana
  ]
}

resource "aws_ssm_parameter" "grafana_admin_username" {
  name  = local.grafana.admin_credentials.username_ssm_parameter_path
  type  = "SecureString"
  value = data.kubernetes_secret_v1.grafana_admin_credentials.binary_data.admin-user

  depends_on = [
    data.kubernetes_secret_v1.grafana_admin_credentials
  ]
}

resource "aws_ssm_parameter" "grafana_admin_password" {
  name  = local.grafana.admin_credentials.password_ssm_parameter_path
  type  = "SecureString"
  value = data.kubernetes_secret_v1.grafana_admin_credentials.binary_data.admin-password

  depends_on = [
    data.kubernetes_secret_v1.grafana_admin_credentials
  ]
}

output "grafana_service_ingress_http_hostname" {
  description = "Grafana service ingress hostname"
  value       = kubernetes_ingress_v1.grafana.status[0].load_balancer[0].ingress[0].hostname

  depends_on = [
    kubernetes_ingress_v1.grafana
  ]
}