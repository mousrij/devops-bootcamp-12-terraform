# This gives back object with certificate-authority among other attributes: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster#attributes-reference
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

# This gives us object with token: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth#attributes-reference  
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.cluster.endpoint
    token = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  }
}

resource "helm_release" "mysql" {
  name       = "module12-exercise-release-2"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mysql"
  version    = "9.10.4"
  timeout    = "100" # seconds (= 16m 40s)

  values = [
    "${file("values.yaml")}"
  ]

  # Set chart values individually
  /* set {
    name  = "volumePermissions.enabled" 
    value = true
  } */
}
