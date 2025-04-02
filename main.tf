#################################################
# EKS CLUSTER
#################################################
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 18.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Use the new VPC
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.private_subnets

  node_groups_defaults = {
    desired_capacity = var.desired_capacity
    max_capacity     = var.max_capacity
    min_capacity     = 1
  }

  node_groups = {
    default = {
      instance_types = [var.instance_type]
      subnets        = module.vpc.private_subnets
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
# KUBERNETES NAMESPACE FOR WEAVIATE
#################################################
resource "kubernetes_namespace" "weaviate" {
  metadata {
    name = "weaviate"
  }
}

#################################################
# HELM RELEASE (Weaviate)
#################################################
resource "helm_release" "weaviate" {
  name       = "weaviate"
  repository = "https://weaviate.github.io/weaviate-helm"
  chart      = "weaviate"
  namespace  = kubernetes_namespace.weaviate.metadata[0].name

  # Pin the chart version or keep it flexible
  version    = "0.6.2"

  # Reference local values.yaml
  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [
    module.eks, 
    kubernetes_storage_class.gp3, 
    kubernetes_namespace.weaviate
  ]
}
