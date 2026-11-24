# --------------------------------------------------
# Strimzi Kafka Operator Helm Release
# --------------------------------------------------

resource "helm_release" "strimzi" {
  name       = "strimzi-cluster-operator"
  repository = "oci://quay.io/strimzi-helm"
  chart      = "strimzi-kafka-operator"
  version    = "1.3.1"

  namespace        = "nextgen-kafka"
  create_namespace = true

  atomic          = true
  cleanup_on_fail = true
  timeout         = 900
  wait            = true

  values = [
    file("${path.module}/../../kubernetes/strimzi/values.yaml")
  ]

  depends_on = [
    module.eks
  ]
}
