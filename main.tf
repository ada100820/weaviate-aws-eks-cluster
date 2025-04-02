#################################################
# EKS CLUSTER CREATION
#################################################
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 18.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.25"

  vpc_id          = var.vpc_id
  subnets         = var.private_subnets

  node_groups_defaults = {
    desired_capacity = var.desired_capacity
    max_capacity     = var.desired_capacity + 2
    min_capacity     = 1
  }

  node_groups = {
    default = {
      instance_types = [var.instance_type]
      subnets        = var.private_subnets
    }
  }
}

data "aws_eks_cluster" "this" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_id
}

#################################################
# (OPTIONAL) CUSTOM STORAGE CLASS FOR gp3
#################################################
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
  }

  storage_provisioner = "kubernetes.io/aws-ebs"

  parameters = {
    type = "gp3"
  }

  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
}

#################################################
# CREATE NAMESPACE FOR WEAVIATE
#################################################
resource "kubernetes_namespace" "weaviate" {
  metadata {
    name = "weaviate"
  }
}

#################################################
# HELM RELEASE FOR WEAVIATE
#################################################
resource "helm_release" "weaviate" {
  name       = "weaviate"
  repository = "https://weaviate.github.io/weaviate-helm"
  chart      = "weaviate"
  namespace  = kubernetes_namespace.weaviate.metadata[0].name

  # Pin the version for stability; adjust as needed:
  version    = "0.6.2"

  # Reference your local values.yaml
  values = [
    file("${path.module}/values.yaml")
  ]

  # If you want to override specific values via Terraform rather than values.yaml:
  # set {
  #   name  = "replicaCount"
  #   value = "3"
  # }

  depends_on = [
    kubernetes_storage_class.gp3,
    kubernetes_namespace.weaviate
  ]
}
