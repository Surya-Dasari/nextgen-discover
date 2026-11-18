
# --------------------------------------------------
# AWS Load Balancer Controller Webhook Access
# --------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "lbc_webhook_from_control_plane" {
  security_group_id = module.security_groups.eks_workers_security_group_id

  referenced_security_group_id = module.eks.cluster_security_group_id

  description = "Allow EKS control plane to reach AWS Load Balancer Controller webhook"

  from_port   = 9443
  to_port     = 9443
  ip_protocol = "tcp"
}


# --------------------------------------------------
# AWS Load Balancer Controller Helm Release
# --------------------------------------------------

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.6.3"

  namespace = "kube-system"

  atomic                     = true
  cleanup_on_fail            = true
  disable_openapi_validation = true
  timeout                    = 900
  wait                       = true

  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "region"
      value = var.aws_region
    },
    {
      name  = "vpcId"
      value = module.vpc.vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "replicaCount"
      value = "2"
    }
  ]
  depends_on = [
    module.eks,
    aws_vpc_security_group_ingress_rule.lbc_webhook_from_control_plane
  ]

}

