## Demo Project - Terraform & AWS EKS

### Topics of the Demo Project
Terraform & AWS EKS

### Technologies Used
- Terraform
- AWS EKS
- Docker
- Linux
- Git

### Project Description
- Automate provisioning EKS cluster with Terraform
- Deploy nginx into the cluster

#### Steps to create a VPC
We use an existing Terraform module provisioning a VPC suitable for use with EKS.

**Step 1:** Create a VPC configuration file\
Open the browser, navigate to [Terraform AWS modules (VPC)](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest?tab=resources), copy the configuration snippet in the "Provision Instructions" box and paste it into a file called `vpc.tf` in the `terraform` folder. Edit the file and save it with the following content:

_terraform/vpc.tf_
```conf
provider "aws" {
  region = "eu-central-1"
}

variable vpc_cidr_block {}
variable private_subnet_cidr_blocks {}
variable public_subnet_cidr_blocks {}

data "aws_availability_zones" "available" {}  # queries the azs in the region of the provider

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "myapp-vpc"
  cidr = var.vpc_cidr_block
  # Best practice for configuring subnets for an EKS cluster: configure one private and one public subnet in each availability zone of the current region.
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets = var.public_subnet_cidr_blocks
  azs = data.aws_availability_zones.available.names 
  
  enable_nat_gateway = true
  single_nat_gateway = true  # all private subnets will route their internet traffic through this single NAT gateway
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"  # for AWS Cloud Control Manager (it needs to know which VPC it should connect to)
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"  # for AWS Cloud Control Manager (it needs to know which subnet it should connect to)
    "kubernetes.io/role/elb" = 1  # for AWS Load Balancer Controller (it needs to know in which subnet to create the load balancer accessible from the internet)
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb" = 1 
  }
}
```

**Step 2:** Vaidate the configuration file\
Now we can initialize the Terraform project and validate it to see if the configuration is syntactically correct so far:

```sh
terraform init
# Initializing the backend...
# Initializing modules...
# Downloading registry.terraform.io/terraform-aws-modules/vpc/aws 5.0.0 for vpc...
# - vpc in .terraform/modules/vpc
# 
# Initializing provider plugins...
# - Finding hashicorp/aws versions matching ">= 5.0.0"...
# - Installing hashicorp/aws v5.1.0...
# - Installed hashicorp/aws v5.1.0 (signed by HashiCorp)
# 
# ...
# 
# Terraform has been successfully initialized!

terraform plan
# data.aws_availability_zones.available: Reading...
# data.aws_availability_zones.available: Read complete after 0s [id=eu-central-1]
# 
# ...
# 
# Terraform will perform the following actions:
#
#   # module.vpc.aws_default_network_acl.this[0] will be created
#   # module.vpc.aws_default_route_table.default[0] will be created
#   # module.vpc.aws_default_security_group.this[0] will be created
#   # module.vpc.aws_eip.nat[0] will be created
#   # module.vpc.aws_internet_gateway.this[0] will be created
#   # module.vpc.aws_nat_gateway.this[0] will be created
#   # module.vpc.aws_route.private_nat_gateway[0] will be created
#   # module.vpc.aws_route.public_internet_gateway[0] will be created
#   # module.vpc.aws_route_table.private[0] will be created
#   # module.vpc.aws_route_table.public[0] will be created
#   # module.vpc.aws_route_table_association.private[0] will be created
#   # module.vpc.aws_route_table_association.private[1] will be created
#   # module.vpc.aws_route_table_association.private[2] will be created
#   # module.vpc.aws_route_table_association.public[0] will be created
#   # module.vpc.aws_route_table_association.public[1] will be created
#   # module.vpc.aws_route_table_association.public[2] will be created
#   # module.vpc.aws_subnet.private[0] will be created
#   # module.vpc.aws_subnet.private[1] will be created
#   # module.vpc.aws_subnet.private[2] will be created
#   # module.vpc.aws_subnet.public[0] will be created
#   # module.vpc.aws_subnet.public[1] will be created
#   # module.vpc.aws_subnet.public[2] will be created
#   # module.vpc.aws_vpc.this[0] will be created
```

Everything seems to be ok. But before we apply it, we need to create the EKS and other resources.

#### Steps to create the EKS cluster and Worker Nodes
Again we use an existing module to provision the EKS cluster. 

**Step 1:** Create an EKS configuration file\
Open the browser, navigate to [Terraform AWS modules (EKS)](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest), copy the configuration snippet in the "Provision Instructions" box and paste it into a file called `eks-cluster.tf` in the `terraform` folder.  Edit the file and save it with the following content:

_terraform/eks-cluster.tf_
```conf
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.2"

  cluster_name = "myapp-eks-cluster"  
  cluster_version = "1.27"  # kubernetes version

  vpc_id = module.vpc.vpc_id                # inspect the available outputs of the vpc module
  subnet_ids = module.vpc.private_subnets   # inspect the available outputs of the vpc module

  eks_managed_node_groups = {  # copied (and adjusted) from the examples on the eks module documentation page
    dev = {
      min_size     = 1
      max_size     = 3
      desired_size = 3

      instance_types = ["t2.small"]
    }
  }

  cluster_endpoint_private_access = false
  cluster_endpoint_public_access = true

  tags = {  # there are no mandatory tags for an eks cluster
    environment = "development"
    application = "myapp"
  }
}
```

**Step 2:** Apply the Configuration Files\
Because we added a new module, we have to execute `terraform init` again.

```sh
terraform init
# Initializing the backend...
# Initializing modules...
# Downloading registry.terraform.io/terraform-aws-modules/eks/aws 19.15.2 for eks...
# - eks in .terraform/modules/eks
# - eks.eks_managed_node_group in .terraform/modules/eks/modules/eks-managed-node-group
# - eks.eks_managed_node_group.user_data in .terraform/modules/eks/modules/_user_data
# - eks.fargate_profile in .terraform/modules/eks/modules/fargate-profile
# Downloading registry.terraform.io/terraform-aws-modules/kms/aws 1.1.0 for eks.kms...
# - eks.kms in .terraform/modules/eks.kms
# - eks.self_managed_node_group in .terraform/modules/eks/modules/self-managed-node-group
# - eks.self_managed_node_group.user_data in .terraform/modules/eks/modules/_user_data
# 
# Initializing provider plugins...
# - Finding hashicorp/cloudinit versions matching ">= 2.0.0"...
# - Reusing previous version of hashicorp/aws from the dependency lock file
# - Finding hashicorp/kubernetes versions matching ">= 2.10.0"...
# - Finding hashicorp/time versions matching ">= 0.9.0"...
# - Finding hashicorp/tls versions matching ">= 3.0.0"...
# - Installing hashicorp/cloudinit v2.3.2...
# - Installed hashicorp/cloudinit v2.3.2 (signed by HashiCorp)
# - Using previously-installed hashicorp/aws v5.1.0
# - Installing hashicorp/kubernetes v2.21.1...
# - Installed hashicorp/kubernetes v2.21.1 (signed by HashiCorp)
# - Installing hashicorp/time v0.9.1...
# - Installed hashicorp/time v0.9.1 (signed by HashiCorp)
# - Installing hashicorp/tls v4.0.4...
# - Installed hashicorp/tls v4.0.4 (signed by HashiCorp)
# 
# Terraform has made some changes to the provider dependency selections recorded
# in the .terraform.lock.hcl file. Review those changes and commit them to your
# version control system if they represent changes you intended to make.
# 
# Terraform has been successfully initialized!

terraform plan
# ...
# Plan: 55 to add, 0 to change, 0 to destroy.

terraform apply --auto-approve
# ...
# Plan: 55 to add, 0 to change, 0 to destroy.
# module.eks.aws_cloudwatch_log_group.this[0]: Creating...
# module.eks.module.eks_managed_node_group["dev"].aws_iam_role.this[0]: Creating...
# module.vpc.aws_vpc.this[0]: Creating...
# module.eks.aws_iam_role.this[0]: Creating...
# ...
# module.eks.aws_eks_cluster.this[0]: Creating...
# ...
# module.eks.aws_eks_cluster.this[0]: Still creating... [10s elapsed]
# ...
# module.eks.aws_eks_cluster.this[0]: Still creating... [9m50s elapsed]
# module.eks.aws_eks_cluster.this[0]: Still creating... [10m0s elapsed]
# ...
# module.eks.aws_eks_cluster.this[0]: Creation complete after 11m3s [id=myapp-eks-cluster]
# ...
# module.eks.module.eks_managed_node_group["dev"].aws_eks_node_group.this[0]: Creating...
# module.eks.module.eks_managed_node_group["dev"].aws_eks_node_group.this[0]: Still creating... [10s elapsed]
# ...
# module.eks.module.eks_managed_node_group["dev"].aws_eks_node_group.this[0]: Still creating... [5m30s elapsed]
# module.eks.module.eks_managed_node_group["dev"].aws_eks_node_group.this[0]: Creation complete after 5m33s [id=myapp-eks-cluster:dev-2023060620561540910000000f]
# 
# Apply complete! Resources: 55 added, 0 changed, 0 destroyed.
```

#### Steps to deploy nginx into the cluster

**Step 1:** Update the kubeconfig file\
Update the kubeconfig file executing the follwoing command:
```sh
aws eks update-kubeconfig --name myapp-eks-cluster --region eu-central-1
# Added new context arn:aws:eks:eu-central-1:369076538622:cluster/myapp-eks-cluster to /Users/fsiegrist/.kube/config
```

**Step 2:** Check the connection\
Now we are connected with our cluster:
```sh
kubctl get nodes
# NAME                                          STATUS   ROLES    AGE   VERSION
# ip-10-0-1-237.eu-central-1.compute.internal   Ready    <none>   38m   v1.27.1-eks-2f008fe
# ip-10-0-2-163.eu-central-1.compute.internal   Ready    <none>   38m   v1.27.1-eks-2f008fe
# ip-10-0-3-28.eu-central-1.compute.internal    Ready    <none>   38m   v1.27.1-eks-2f008fe
```

**Step 3:** Deploy nginx into the cluster
```sh
kubectl apply -f ../k8s/nginx-config.yaml
# deployment.apps/nginx created
# service/nginx created

kubectl get pods
# NAME                    READY   STATUS    RESTARTS   AGE
# nginx-55f598f8d-cpkft   1/1     Running   0          24s

kubectl get services
# NAME         TYPE           CLUSTER-IP       EXTERNAL-IP                                                                  PORT(S)        AGE
# kubernetes   ClusterIP      172.20.0.1       <none>                                                                       443/TCP        50m
# nginx        LoadBalancer   172.20.140.214   a8052fa527f3f4ffd8833a94039e849f-1687828084.eu-central-1.elb.amazonaws.com   80:31680/TCP   42s
```

**Step 4:** Open the nginx welcome page in the browser\
Open the browser and navigate to 'http://a8052fa527f3f4ffd8833a94039e849f-1687828084.eu-central-1.elb.amazonaws.com'. You should see the nginx welcome page.

You can find this URL also in the AWS Management Console > EC2 Dashboard > Load Balancers, select the load balancer in the list, open the "Description" tab and copy the DNS name from the "Basic Configuration" section.

#### Steps to destroy all components (optional)
When you're done with the cluster you can very easily remove all the resources by executing `terraform destroy`. But because we deployed a LoadBalancer service, a cloud-native LoadBalancer has been created Terraform doesn't know about. The subnets created by Terraform cannot be destroyed as long as the network interfaces are in use by the LoadBalancer. So we first have to undeploy the LoadBalancer service.

```sh
kubectl delete -f ../k8s/nginx-config.yaml

terraform destroy --auto-approve
# this will take around 10 minutes

terraform state list
# should return nothing
```