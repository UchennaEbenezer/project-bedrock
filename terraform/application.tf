# Deploy the custom Helm Chart for the Retail Store Sample App
resource "helm_release" "retail_app" {
  name      = "retail-store-sample-app"
  chart     = "${path.module}/../kubernetes/retail-store-sample-app"
  namespace = kubernetes_namespace.retail.metadata[0].name

  values = [
    local_file.helm_values.content
  ]

  depends_on = [
    aws_eks_node_group.main,
    aws_db_instance.mysql,
    aws_db_instance.postgres,
    aws_dynamodb_table.carts,
    kubernetes_secret.catalog_db,
    kubernetes_secret.orders_db,
    helm_release.alb_controller
  ]
}
