module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.15.3"

  cluster_name    = var.cluster_name
  cluster_version = var.k8s_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  cluster_endpoint_private_access = false
  cluster_endpoint_public_access = true

  tags = {
    Environment = "bootcamp"
    Terraform = "true"
  }

  eks_managed_node_groups = {
    dev = {
      min_size     = 1
      max_size     = 3
      desired_size = 3

      instance_types = ["t3.small"]
      labels = {
        Environment = var.env_prefix
      }
    }
  }

  fargate_profiles = {
    default = {
      name = "module12-exercise-fargate-profile"
      selectors = [
        {
          namespace = "module12-exercise-namespace"
        }
      ]
    }
  }
}