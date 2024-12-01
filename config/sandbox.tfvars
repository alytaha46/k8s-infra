tags = {
  Project         = "k8s-task"
  Environment     = "SANDBOX"
  ManagedBy       = "alytaha46@gmail.com"
  Terraform       = "true"
}

############################################
################ VPC #######################
############################################
vpc_name         = "k8s-task-vpc"
vpc_cidr         = "10.0.0.0/16"
vpc_azs          = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets   = ["10.0.3.0/24", "10.0.4.0/24"]

############################################
################ EKS #######################
############################################

cluster_name                          = "k8s-task-cluster"
cluster_version                       = "1.31"
cluster_endpoint_public_access        = true
cluster_endpoint_public_access_cidrs  = ["102.191.148.166/32"]

cluster_addons = {
  eks-pod-identity-agent = {}
  kube-proxy             = {}
  coredns                = {}
}

eks_managed_node_groups = {
  node_groups = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["t3.medium"]
    min_size       = 1
    max_size       = 1
    desired_size   = 1
  }
}

enable_cluster_creator_admin_permissions = true

access_entries = {
  user = {
    principal_arn     = "arn:aws:iam::651980439276:user/alytaha46"

    policy_associations = {
      example = {
        policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
          type = "cluster"
        }
      }
    }
  }
}