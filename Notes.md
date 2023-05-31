## Notes on the videos for Module 12 "Infrastructure as Code with Terraform"
<br />

<details>
<summary>Video: 1 - Introduction to Terraform</summary>
<br />

Terraform is an open-source infrastructure as code (IaC) or infrastructure provisioning tool by HashiCorp. It let's you automate and manage:
- your infrastructure
- your platform
- services that run on that platform

You do so by defining the resources in human-readable configuration files which you
can version, reuse and share.

The configuration files are defined in a declarative way, so you define WHAT end result or desired state you want and Terraform will figure out how to do it.

Before you can deploy your applications to an infrastructure like AWS you have to provision this infrastructure. With AWS for example you have to create a private network space, setup EC2 server instances, install Docker and other tools on them, configure security (firewalls etc.) and so on. With Terraform you can automate these steps, manage continuous changes to your infrastructure and easily replicate the same infrastructure on different environments like DEV, STAGE, PROD.

### Difference of Terraform and Ansible
Both are IaC tools, but
- **Terraform** is mainly an infrastructure provisioning tool. It is more advanced in orchestration and better for provisioning the infrastructure. It is relatively new.
- Whereas **Ansible** is mainly a configuration mangenment tool and better for configuring the provisioned infrastructure and deploying applications on it. It is more mature.

### Terraform Architecture
How does Terraform connect to the platform provider? It has two main components:
- the **Core** takes two input sources:
  - TF config-files (.tf), where you define what to create and configure
  - TF state (terraform.tfstate), which contains the current state of the infrastructure setup
  
  The core then compares the current state with the desired state (config files) and figures out what has to be created, updated or destroyed to reach the desired state.
- **Providers** for specific technologies like AWS (IaaS), Azure (IaaS), Kubernetes (PaaS), Fastly (SaaS). Currently there are more than a 100 providers giving access to over 1000 resources.

Once the core has built its plan to transition from the current state to the desired state it uses providers to execute the actual steps.

### Example Configuration Files
```conf
# Configure the AWS Provider
provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}
```

```conf
# Configure the Kubernetes Provider
provider "kubernetes" {
  config_context_auth_info = "ops"
  config_context_cluster   = "mycluster"
}

# Create a Namespace
resource "kubernetes_namespace" "example" {
  name = "my-first-namespace"
}
```

### Terraform Commands
- `refresh`: query infrastructure provider to get current state
- `plan`: create an execution plan and review it
- `apply`: actually execute the plan
- `destroy`: destroy the resources/infrastructure

`apply` and `destroy` can be called without first calling `refresh` or `plan`. They will both automatically call these two other commands before doing their own job.

### Links
- [Terraform](https://developer.hashicorp.com/terraform)

</details>

*****

<details>
<summary>Video: 2 - Install Terraform & Setup Terraform Project</summary>
<br />

Open the [Terraform Download Page](https://developer.hashicorp.com/terraform/downloads) to get instructions on how to install Terraform on the various operating systems.

On a Mac the easiest way to install and update Terraform is using the package manager homebrew:
```sh
# install
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# check installation
terraform -v
# Terraform v1.4.6
# on darwin_arm64

# update
brew update
brew upgrade hashicorp/tap/terraform
```

### Local Setup
The examples use AWS as the target platform. But the commands would be similar on other platforms.

First we create a folder where we are going to execute our demo commands:
```sh
mkdir terraform
cd terraform

touch main.tf
```

If you want to edit the files in VS Code you can install a plugin (e.g. the official one by Hashicorp or the one by Anton Kulikov) to get syntax highlighting and auto-completion.

</details>

*****

<details>
<summary>Video: 3 - Providers in Terraform</summary>
<br />

### Providers
A Terraform-Provider is a plugin Terraform uses to manage the resources. It exposes the resources for a specific infrastructure platform (e.g. AWS) and is responsible for understanding the API of that platform. So it is just code that knows how to talk to a specific technology or platform.

On the [Terraform Registry Page](https://registry.terraform.io/browse/providers) you find a list of all the currently available providers. Click on AWS > Documentation to get instructions on how to use this provider. Documentation is available for all the providers which makes it very convenient to work with and use Terraform.

### Install and Connect to Provider
To install a provider we first need to have a .tf file declaring that provider. So open the `terraform/main.tf` file and add the following content:
```conf
provider "aws" {
    region = "eu-central-1"
    access_key = "your-aws-access-key-id"
    secret_key = "your-aws-secret-access-key"
}
```

Note that Terraform configuration files are meant to be checked in as part of the project's source code to the Git repository. Therefore you should never write credentials into these files. In the case of access-key and secret-key you could omit them and set according environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` instead. But we will see other possibilities to reference credentials soon.

Now that we have declared a provider in the configuration file we can install it by executing the following command (note that we have to be in the same directory as the configuration file when executing the command):
```sh
terraform init
# Initializing the backend...

# Initializing provider plugins...
# - Finding latest version of hashicorp/aws...
# - Installing hashicorp/aws v4.67.0...
# - Installed hashicorp/aws v4.67.0 (signed by HashiCorp)

# Terraform has created a lock file .terraform.lock.hcl to record the provider
# selections it made above. Include this file in your version control repository
# so that Terraform can guarantee to make the same selections by default when
# you run "terraform init" in the future.

# Terraform has been successfully initialized!
```

This command downloaded the provider and put it into a local `.terraform/providers/` folder. You should gitignore the `.terraform` folder. The file `.terraform.lock.hcl` however, which was also created and keeps track of the installed providers, should be checked in to Git repository.

It is recommended (and for non-offical providers - with a source other than hashicorp - even mandatory) to explicitly declare all the providers used in the project in a `required_providers` block like this:
```conf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.67.0"
    }

    linode = {
      source = "linode/linode"
      version = "2.2.0"
    }
  }
}
```
You find that block on the provider page by pressing the "USE PROVIDER" button at the top right. You may add this block to the main configuration file or even put it in a separate file, e.g. `providers.tf`.

### Providers Exposing Resources
Providers provide access to the complete API of the related platform. You find a list of all available resources on the documentation page of the provider (on the left).

</details>

*****

<details>
<summary>Video: 4 - Resources & Data Sources</summary>
<br />

### Resources
To create a resource we have to know its id. Resource ids start with the provider name followed by an underscore and the resource name, e.g. 'aws_vpc'.

#### Examples
```conf
resource "aws_vpc" "my-test-vpc" {
  cidr_block = "10.0.0.0/16"
}
```

The second parameter (after the resource id) is a name we can give the resource to reference it from other parts of the configuration:
```conf
resource "aws_subnet" "my-test-subnet-1" {
  vpc_id = aws_vpc.my-test-vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "eu-central-1a"
}
```

#### Create the Declared Resources
To create the resources declared in the main.tf file, we execute the following command from inside the folder containing the configuration file (`terraform` in our case):
```sh
terraform apply
# Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
#   + create
# 
# Terraform will perform the following actions:
# 
#   # aws_subnet.my-test-subnet-1 will be created
#   + resource "aws_subnet" "my-test-subnet-1" {
#       + arn                                            = (known after apply)
#       + assign_ipv6_address_on_creation                = false
#       + availability_zone                              = "eu-central-1a"
#       + availability_zone_id                           = (known after apply)
#       + cidr_block                                     = "10.0.10.0/24"
#       + enable_dns64                                   = false
#       + enable_resource_name_dns_a_record_on_launch    = false
#       + enable_resource_name_dns_aaaa_record_on_launch = false
#       + id                                             = (known after apply)
#       + ipv6_cidr_block_association_id                 = (known after apply)
#       + ipv6_native                                    = false
#       + map_public_ip_on_launch                        = false
#       + owner_id                                       = (known after apply)
#       + private_dns_hostname_type_on_launch            = (known after apply)
#       + tags_all                                       = (known after apply)
#       + vpc_id                                         = (known after apply)
#     }
# 
#   # aws_vpc.my-test-vpc will be created
#   + resource "aws_vpc" "my-test-vpc" {
#       + arn                                  = (known after apply)
#       + cidr_block                           = "10.0.0.0/16"
#       + default_network_acl_id               = (known after apply)
#       + default_route_table_id               = (known after apply)
#       + default_security_group_id            = (known after apply)
#       + dhcp_options_id                      = (known after apply)
#       + enable_classiclink                   = (known after apply)
#       + enable_classiclink_dns_support       = (known after apply)
#       + enable_dns_hostnames                 = (known after apply)
#       + enable_dns_support                   = true
#       + enable_network_address_usage_metrics = (known after apply)
#       + id                                   = (known after apply)
#       + instance_tenancy                     = "default"
#       + ipv6_association_id                  = (known after apply)
#       + ipv6_cidr_block                      = (known after apply)
#       + ipv6_cidr_block_network_border_group = (known after apply)
#       + main_route_table_id                  = (known after apply)
#       + owner_id                             = (known after apply)
#       + tags_all                             = (known after apply)
#     }
# 
# Plan: 2 to add, 0 to change, 0 to destroy.
# 
# Do you want to perform these actions?
#   Terraform will perform the actions described above.
#   Only 'yes' will be accepted to approve.
# 
#   Enter a value: 
```

Enter `yes` to apply the plan.
```sh
#   Enter a value: yes
# 
# aws_vpc.my-test-vpc: Creating...
# aws_vpc.my-test-vpc: Creation complete after 4s [id=vpc-0e78ddaf9fbd7667e]
# aws_subnet.my-test-subnet-1: Creating...
# aws_subnet.my-test-subnet-1: Creation complete after 0s [id=subnet-08b399d5808d62d36]
# 
# Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Going to your account in the AWS Management Console, you should find the created VPC and Subnet.

### Data Sources
`resources` lets you create new resources, whereas `data` lets you query existing resources.

#### Examples
```conf
data "aws_vpc" "existing_default_vpc" {
  default = true
}
```

The second parameter (after the resource id) is a name (provided by us) under which the result of the query will be exported and with which it can be referenced from within other resource declarations.

The arguments inside the block are the filter for the query. All the possible arguments are described on the Terraform documentation page for the provider (together with the resource documentation).

Let's see how to reference data:
```conf
resource "aws_subnet" "my-test-subnet-2" {
  vpc_id = data.aws_vpc.existing_default_vpc.id
  cidr_block = "172.31.48.0/20"
  availability_zone = "eu-central-1a"
}
```

Apply the changes executing `terraform apply` again. This time terraform is refreshing the state before creating a plan:
```conf
terraform apply
# data.aws_vpc.existing_default_vpc: Reading...
# aws_vpc.my-test-vpc: Refreshing state... [id=vpc-0e78ddaf9fbd7667e]
# data.aws_vpc.existing_default_vpc: Read complete after 1s [id=vpc-04acd8f40d2f4b8e9]
# aws_subnet.my-test-subnet-1: Refreshing state... [id=subnet-08b399d5808d62d36]
# ...
# aws_subnet.my-test-subnet-2: Creating...
# aws_subnet.my-test-subnet-2: Creation complete after 1s [id=subnet-0620ee24e8f6379e9]
# 
# Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

</details>

*****

<details>
<summary>Video: 5 - Change & Destroy Terraform Resources</summary>
<br />

### Changing Resources
Let's add names to our VPC and subnets. On AWS resources this is done via tags. Tags can be any key-value-pairs. However there is one key reserved for resource names: `Name`.
```conf
resource "aws_vpc" "my-test-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name: "test-vpc"
  }
}

resource "aws_subnet" "my-test-subnet-1" {
  vpc_id = aws_vpc.my-test-vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    Name: "test-subnet-1"
  }
}

resource "aws_subnet" "my-test-subnet-2" {
  vpc_id = data.aws_vpc.existing_default_vpc.id
  cidr_block = "172.31.48.0/20"
  availability_zone = "eu-central-1a"
  tags = {
    Name: "test-subnet-2"
  }
}
```

Apply the changes. Note that changes are displayed with a leading `~` (tilde) character:
```sh
#   # aws_subnet.my-test-subnet-1 will be updated in-place
#   ~ resource "aws_subnet" "my-test-subnet-1" {
#         id                                             = "subnet-08b399d5808d62d36"
#       ~ tags                                           = {
#           + "Name" = "test-subnet-1"
#         }
#       ~ tags_all                                       = {
#           + "Name" = "test-subnet-1"
#         }
#         # (15 unchanged attributes hidden)
#     }
```

In the same way attribues can be removed or modified. Removals are displayed with a leading `-` (minus) character.

### Removing / Destroying Resources
To remove a whole resource we can either remove it from the main.tf file and re-apply the file, or we can use a terrform command:
```sh
terraform destroy -target aws_subnet.my-test-subnet-2
```

When you destroy a resource using the command, you end up with a configuration file which is no longer representing the current state. That's why it is recommended to always modify and apply the configuration file instead of using the destroy command.

</details>

*****

<details>
<summary>Video: 6 - Terraform commands</summary>
<br />

### More Terraform Commands
If you want to display the difference between the current state and the desired state (described in the current configuration file), you can execute the plan command. It gives you the same output as the `apply` command but without asking you whether you want to apply the changes (and without applying them, of course).
```sh
terraform plan
```

To apply changes without displaying the planned steps and without asking you for confirmation, execute
```sh
terraform apply -auto-approve
```

If you want to destroy all the resources declared in the configuration file, just execute
```sh
terraform destroy
```

Terraform will figure out the correct order in which the resources have to be destroyed.

</details>

*****

<details>
<summary>Video: 7 - Terraform State</summary>
<br />

### State
Terraform stores the current state in a file called `terraform.tfstate` next to your configuration file(s). It is a JSON file where Terraform stores the state of your real world resources of your managed infrastructure.

This file can quickly become quite large. Terraform provides commands to query the content of the state file.

```sh
terraform state list
# data.aws_vpc.existing_default_vpc
# aws_subnet.my-test-subnet-1
# aws_subnet.my-test-subnet-2
# aws_vpc.my-test-vpc

terraform state show aws_subnet.my-test-subnet-1
# # aws_subnet.my-test-subnet-1:
# resource "aws_subnet" "my-test-subnet-1" {
#     arn                                            = "arn:aws:ec2:eu-central-1:369076538622:subnet/subnet-08b399d5808d62d36"
#     assign_ipv6_address_on_creation                = false
#     availability_zone                              = "eu-central-1a"
#     availability_zone_id                           = "euc1-az2"
#     cidr_block                                     = "10.0.10.0/24"
#     enable_dns64                                   = false
#     enable_lni_at_device_index                     = 0
#     enable_resource_name_dns_a_record_on_launch    = false
#     enable_resource_name_dns_aaaa_record_on_launch = false
#     id                                             = "subnet-08b399d5808d62d36"
#     ipv6_native                                    = false
#     map_customer_owned_ip_on_launch                = false
#     map_public_ip_on_launch                        = false
#     owner_id                                       = "369076538622"
#     private_dns_hostname_type_on_launch            = "ip-name"
#     tags                                           = {
#         "Name" = "test-subnet-1"
#     }
#     tags_all                                       = {
#         "Name" = "test-subnet-1"
#     }
#     vpc_id                                         = "vpc-0e78ddaf9fbd7667e"
# }
```

The second command is useful when you want to see what attributes are available for a certain resource. 

</details>

*****

<details>
<summary>Video: 8 - Output Values</summary>
<br />

### Output
Output values are like return values of functions. You can add them in your configuration files to output any values you are interested in.
```conf
output "test-vpc-id" {
  value = aws_vpc.my-test-vpc.id
}

output "test-subnet-1-id" {
  value = aws_subnet.my-test-subnet-1.id
}
```

After the `output` keyword you provide a name of the output. The attribute `value` references the recource attribute you want to output.

```sh
terraform destroy -auto-approve
terraform apply -auto-approve
# ...
# Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
# 
# Outputs:
# 
# test-subnet-1-id = "subnet-09e36c91e8cf7dca1"
# test-vpc-id = "vpc-0787a1e569414e86b"
```

</details>

*****

<details>
<summary>Video: 9 - Variables in Terraform</summary>
<br />

Variables are defined and referenced as follows:
```conf
variable "subnet_cidr_block" {
  description = "subnet cidr block"
}

resource "aws_subnet" "my-test-subnet-1" {
  vpc_id = aws_vpc.my-test-vpc.id
  cidr_block = var.subnet_cidr_block # <---
  availability_zone = "eu-central-1a"
  tags = {
    Name: "test-subnet-1"
  }
}
```

There are three ways to pass a value to the input variable:
- If you just execute `terraform apply` you will be prompted for entering a value for the variable `subnet_cidr_block`
- You can pass in the variable value as an argument to the `terraform apply` command like this:
  `terraform apply -var "subnet_cidr_block=10.0.30.0/24"`
- You can create a file called `terraform.tfvars` containing all the variables and their values (in the format `variable_name = value`). When applying the main.tf configuration file, Terraform will automatically inspect the file called `terraform.tfvars` and substitute the variable references found in main.tf with the values found inside this file. Like this you can use the same main.tf file with different .tfvars files for different environments. In this case you would have to pass the name of the variables file to the `terraform apply` command like this:
`terraform apply -var-file terraform-dev.tfvars`

### Default Values
Inside the `variables` block you can define a default value:
```conf
variable "subnet_cidr_block" {
  description = "subnet cidr block"
  default = "10.0.10.0/24"
}
```

The default value kicks in if you don't pass in a value either via the `-var` option or a variables file.

### Type constraints
You can define a variable type using the `type` attribute within the `variable` block:
```conf
variable "subnet_cidr_block" {
  description = "subnet cidr block"
  type = string # number, boolean, list(<TYPE>), set(<TYPE>), map(<TYPE>), object({<ATTR_NAME> = <TYPE>, ...}), tuple([<TYPE>, ...])
  default = "10.0.10.0/24"
}
```

#### More complex example
_main.tf_
```conf
variable "cidr_blocks" {
  description = "cidr blocks for vpc and subnet"
  type = list(object({
    cidr_block = string
    name = string
  }))
}

resource "aws_vpc" "my-test-vpc" {
  cidr_block = var.cidr_blocks[0].cidr_block
  tags = {
    Name: var.cidr_blocks[0].name
  }
}

resource "aws_subnet" "my-test-subnet-1" {
  vpc_id = aws_vpc.my-test-vpc.id
  cidr_block = var.cidr_blocks[1].cidr_block
  availability_zone = "eu-central-1a"
  tags = {
    Name: var.cidr_blocks[1].name
  }
}
```

_terraform.tfvars_
```conf
cidr_block = [
  { cidr_block = "10.0.0.0/16", name = "test-vpc" },
  { cidr_block = "10.0.10.0/24", name = "test-subnet-1" }
]
```

</details>

*****

<details>
<summary>Video: 10 - Environment Variables in Terraform</summary>
<br />

Credentials should not be written hardcoded into a file which is checked in to source control repository.

AWS credentials can be provided in two other ways than writing them into the configuration file. You can either set environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` or you can just add them to the file `~/.aws/credentials` (using `aws configure` for example). So setting the credentials for the provider can usually be done via environment variables or a provider specific way of configuring your local machine to authenticate against the provider. The details should be found in the documentation of each provider.

### Predefined Terraform Environment Variables
Terraform has predefined environment variables, which you can use to change some of Terraform's default behavior, for example enabling detailed logs.
```sh
export TF_LOG=trace
export TF_LOG=off
```

See [documentation](https://developer.hashicorp.com/terraform/cli/config/environment-variables).

### Define and Use Custom Environment Variables
Custom environment variables must have the prefix `TF_VAR_`. The remaining part of the name can be used to define a varibale in the configuration file like this:
```sh
export TF_VAR_avail_zone="eu-central-1a"
```

```conf
variable "avail_zone" {} # <---

resource "aws_subnet" "my-test-subnet-1" {
  vpc_id = aws_vpc.my-test-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone # <---
  tags = {
    Name: "test-subnet-1"
  }
}
```

This is technically the 4th way of setting a variable value, because we define a variable and set its value through a Terraform environment variable.

</details>

*****

<details>
<summary>Video: 11 - Create Git Repository for local Terraform Project</summary>
<br />

Like your application code, Terraform scripts being infrastructure as code, should be managed by version control system Git and be hosted in a Git repository.

Best Practice:
- Have a separate Git repository for application code and Terraform code.

When adding a Terraform project to a Git repository, the following folders and files don't have to be checked in and should be added to `.gitignore`:
- the `.terraform` folder -> `**/.terraform/*`
- the state file and its backup -> `*.tfstate` and `*.tfstate.*`
- the variable files as they may contain sentitive data -> `*.tfvars`

</details>

*****

<details>
<summary>Video: 12 - Automate Provisioning EC2 with Terraform - Part 1</summary>
<br />

### Overview
We're going to provision an EC2 instance on AWS infrastructure and then run an nginx Docker container on that EC2 instance. Using Terraform we're going to 
- create a custom VPC
- create a custom Subnet in one of the availability zones
- create a Route Table & Internet Gateway
- provision EC2 instance
- deploy nginx Docker container
- create a Security Group (firewall)

A best practice when working with Terraform is to ceate the infrastructure from scratch and leave the defaults created by AWS as is. This makes it easier to clean up and remove all the components created by Terraform when you don't need them anymore. That's why we don't use the default VPC but create our own custom VPC.

### Create a VPC and a Subnet
Let's start with a `main.tf` file with the following content:

_main.tf_
```conf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {} # <--- dev, stage, prod

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix}-vpc" # <--- string interpolation
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name = "${var.env_prefix}-subnet-1"
    }
}
```

Create a `terraform.tfvars` file setting the four variables:

_terraform.tfvars_
```conf
vpc_cidr_block = "10.0.0.0/16"
subnet_cidr_block = "10.0.10.0/24"
avail_zone = "eu-central-1a"
env_prefix = "dev"
```

Check what Terraform is going to do and if everything looks fine, apply the changes:
```sh
terraform plan
terraform apply -auto-approve
# ...
# aws_vpc.myapp-vpc: Creating...
# aws_vpc.myapp-vpc: Creation complete after 2s [id=vpc-09d8a5e6df029965c]
# aws_subnet.myapp-subnet-1: Creating...
# aws_subnet.myapp-subnet-1: Creation complete after 0s [id=subnet-049b7bc24b07a9ca7]
# 
# Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

### Route Table & Internet Gateway
Login to your AWS Management Console and navigate to the VPC dashboard. Click on the `dev-vpc` entry. In the `Details` section you see that AWS automatically generated a Route Table (a virtual router in our VPC, defining where the traffic will be forwarded to whithin the VPC). AWS also generated a Network ACL. An NACL is a firewall configuration for Subnets whereas a Security Group is a firewall configuration for servers. In NACLs every port is open by default. In security groups all the ports are closed by default.

Click on the route table link in the VPC details section and again on the ID link of the route table. In the Routes section you see that the route table only contains one route entry handling the traffic for all the IP addresses in the VPC range (Destination = 10.0.0.0/16) but only locally (Target = local), i.e. only VPC-internal traffic. There's no internet gateway configured connecting the Internet with our VPC (Destination = 0.0.0.0/0, Target = igw).

Following the best practice, we don't add a route to the route table automatically created by AWS, but we create a new Route Table containing the two entries we need. The entry concerning the traffic of the VPC IP range (with Target = local) is created for each route table and cannot be created manually (or by Terraform). So we only have to define an entry for the internet connectivity. Add the folloing resources to the main.tf file:

```conf
resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name = "${var.env_prefix}-igw"
    }
}

resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name = "${var.env_prefix}-rtb"
    }
}
```

Check and apply the changes:
```sh
terraform plan
terraform apply -auto-approve
# aws_internet_gateway.myapp-igw: Creating...
# aws_internet_gateway.myapp-igw: Creation complete after 0s [id=igw-0376d90b54fcef3ad]
# aws_route_table.myapp-route-table: Creating...
# aws_route_table.myapp-route-table: Creation complete after 1s [id=rtb-051c151beb22a9536]
# 
# Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Check the new route table and the internet gateway in the AWS Management Console.

### Subnet Association with Route Table
Currently our subnet is not yet associated with the route table we created via Terraform. Subnets that haven't been explicitly associated with a route table are assotiated by AWS with the main route table of the VPC, which is the one that was created by AWS automatically when we created the VPC. So we have to create a route table association now, because we want our subnet to be connected with the internet too. (Note that in the AWS Management Console it is called a 'subnet association', but the aws provider resource is called a 'route table association').

Add the following content to the `main.tf` file and apply the changes:
```conf
resource "aws_route_table_association" "assoc-rtb-subnet" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}
```

### Using the Main Route Table
If we wanted to use the main route table automatically created by AWS and add the route providing internet connectivity to this route table (instead of creating our own route table), we could do that as well adding the following resource to the configuration:

```conf
resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name = "${var.env_prefix}-main-rtb"
    }
}
```

The attribute name 'default_route_table_id' can be found inspecting the VPC in the current state:
```sh
terraform state show aws_vpc.myapp-vpc
# # aws_vpc.myapp-vpc:
# resource "aws_vpc" "myapp-vpc" {
#     arn                                  = "arn:aws:ec2:eu-central-1:369076538622:vpc/vpc-09d8a5e6df029965c"
#     assign_generated_ipv6_cidr_block     = false
#     cidr_block                           = "10.0.0.0/16"
#     default_network_acl_id               = "acl-0d26c6c537ac824b1"
#     default_route_table_id               = "rtb-0ee7bd1fb740d6ba3"
#     default_security_group_id            = "sg-00e940c469d455b57"
#     ...
#     id                                   = "vpc-09d8a5e6df029965c"
#     ...
# }
```

When you apply these changes the existing main route table created by AWS is replaced by a new main route table with the same id but with the additional route.

Note that this time we don't have to explicitly create a route-table-subnet-association between this new main route table and our subnet because subnets not explicitly associated with a route table get automatically associated with the main route table as mentioned above.

### Security Group
To configure firewall rules for the EC2 instance we want to create (open port 22 for ssh and port 8080 to access the nginx server), we need to create a security group.

Add the folloing resource to the configuration file:

```conf
resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}
```

The security group contains two ingress rules (controlling incomming traffic) and one egress rule (controlling outgoing traffic). We want to allow incoming ssh requests (on port 22) to be able to ssh into the EC2 instance, and http requests on port 8080 to be able to access the nginx server with our browser. And we want to allow any outgoing requests to be able to pull the nginx Docker image.
The port declared in a firewall rule can actually be a port range, that's why we define a `port_from` and `port_to` value. The port 22 must only be open for requests from our IP address, so we don't write it directly into the configuration file but define a variable for it.

Add `variable my_ip {}` to the list of variables in the configuration file and add an entry `my_ip = "nnn.nnn.nnn.nnn/32"` to the terraform.tfvars file (replace nnn.nnn.nnn.nnn with your IP address).

Now check and apply the changes. Inspect the applied security group in the AWS Management Console (EC2 dashboard > Security Groups or VPC dashboard > Security Groups).

### Using the Default Security Group
As with the main routing table we can also reuse the default security group created by AWS when creating a VPC and add the ingress and egress rules instead of creating a new custom security group.

To do so just take the resource definition of our custom security group, change the resource id to `aws_default_security_group`, remove the `name` attribute and adjust the tags if you want. The ingress and outgress definitions stay the same:

```conf
resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags = {
        Name = "${var.env_prefix}-default-sg"
    }
}
```

Again, when applying this resource definition, the original default security group gets replaced by a new one with the same id but with different rules.

</details>

*****

<details>
<summary>Video: 13 - Automate Provisioning EC2 with Terraform - Part 2</summary>
<br />

Now let's create an EC2 instance.

### Amazon Machine Image (AMI) for EC2
First of all we need an Amazon Machine Image (AMI) which will be used as a template for the EC2 virtual machine. We could go to the AWS Management Console and look up the id of the AMI we want to use. But this id may change when Amazon updates the image. So instead of hardcoding it into the configuration file, we define a `data` querying the latest version of the image we want to use (the AMI name can be found in in EC2 > AMI Catalog > Community AMIs):

```conf
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}
```

To test whether the `data` queries the expected AMI add the following `output` to the configuration:

```conf
output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
}
```

Execute `terraform plan` to se the output and compare it with the id displayed in the AWS Management Console.

Now we can reference this `data` in the resource definition for the EC2 instance:

```conf
resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
}
```

### Create EC2 Instance
The second required attribute (besides `ami`) is the `instance_type`. We set it to `t2.micro` but don't write it hardcoded into the configuration file, but rather define a variable and add the value to the `terraform.tfvars` file:

_main.tf_
```conf
variable instance_type {}
...
resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type
}
```

_terraform.tfvars_
```conf
...
instance_type = "t2.micro"
```

All the other attributes are optional but we set some of them because we want the EC2 to be running in our VPC and use our security group and so on. The final resource definition will look like this:

```conf
resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = "server-key-pair"

    tags = {
        Name = "${var.env_prefix}-server"
    }
}
```

For being able to ssh into the EC2 instance we have to create a key pair. The name of the key pair is then set as the value of the attribute `key_name`.

To create the key pair open the AWS Management Console, make sure you're in the right region, go to the EC2 dashboard and click on the 'Key pairs' link. Press the 'Create key pair' button, enter a key pair name (e.g. 'server-key-pair'), select the type (RSA or ED25519), a format (.pem) and press 'Create key pair'. A `server-key-pair.pem` file gets downloaded automatically.

Move the downloaded file into the `~/.ssh` directory and reduce its file permissions to user-read-only:
```sh
mv ~/Downloads/server-key-pair.pem ~/.ssh/
chmod 400 ~/.ssh/server-key-pair.pem
```

Apply the changes:
```sh
terraform plan
terraform apply --auto-approve
# ...
# aws_instance.myapp-server: Creating...
# aws_instance.myapp-server: Still creating... [10s elapsed]
# aws_instance.myapp-server: Still creating... [20s elapsed]
# aws_instance.myapp-server: Creation complete after 22s [id=i-0b063121922c765b6]
```

As soon as the EC2 instance state in the AWS Management Console is 'Running' we can ssh into the instance. Copy the public IP address from the 'Instance summary' page and execute the following command in your local machine's terminal:
```sh
ssh -i ~/.ssh/server-key-pair.pem ec2-user@<public-ip>
```

To get the public IP address directly when applying the configuration file, we can add the following `output` configuration:
```conf
output "ec2_public_ip" {
    value = aws_instance.myapp-server.public_ip
}
```

### Automate SSH Key Pair
Creating the key pair was a manual step. We should try to automate as many steps as possible. So let's use an existing key pair we created on our local machine and copy the public key to the EC2 instance.

Add the following content to the configuration file...

_main.tf_
```conf
variable public_key_location {}
...
resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = file(var.public_key_location)
}
```

... and replace the key-pair reference in the `aws_instance` resource:

_main.tf_
```conf
resource "aws_instance" "myapp-server" {
    ...
    key_name = aws_key_pair.ssh-key.key_name
    ...
}
```

Don't forget to set the `public_key_location` variable:

_terraform.tfvars_
```conf
public_key_location = "/Users/fsiegrist/.ssh/id_ed25519.pub"
```

Apply the changes. Because it is not possible to replace the key pair in a running EC2 instance the existing instance is destroyed and a new one is created:

```sh
terraform apply --auto-approve
# ...
# aws_key_pair.ssh-key: Creating...
# aws_instance.myapp-server: Destroying... [id=i-0b063121922c765b6]
# aws_key_pair.ssh-key: Creation complete after 0s [id=server-key]
# aws_instance.myapp-server: Still destroying... [id=i-0b063121922c765b6, 10s elapsed]
# aws_instance.myapp-server: Still destroying... [id=i-0b063121922c765b6, 20s elapsed]
# aws_instance.myapp-server: Still destroying... [id=i-0b063121922c765b6, 30s elapsed]
# aws_instance.myapp-server: Destruction complete after 30s
# aws_instance.myapp-server: Creating...
# aws_instance.myapp-server: Still creating... [10s elapsed]
# aws_instance.myapp-server: Still creating... [20s elapsed]
# aws_instance.myapp-server: Still creating... [30s elapsed]
# aws_instance.myapp-server: Creation complete after 32s [id=i-0994aec0c5300e204]
# 
# Apply complete! Resources: 2 added, 0 changed, 1 destroyed.
# 
# Outputs:
# 
# aws_ami_id = "ami-08e415170f52d1657"
# ec2_public_ip = "3.72.36.170"
```

SSH into the new instance (the public IP address is at the bottom of the output of the apply command). Since we use our own private key stored at the default location we don't have to specify the path to the private key file:

```sh
ssh ec2-user@3.72.36.170
```

Finally you can delete the old server-key-pair manually in the AWS Management Console and remove the file `~/.ssh/server-key-pair.pem` from your local machine.

</details>

*****

<details>
<summary>Video: 14 - Automate Provisioning EC2 with Terraform - Part 3</summary>
<br />

### Run Entrypopint Script to start Docker Container
By now we have a running EC2 instance but there is no application deployed on it. We want to automate the process of installing Docker and running a container too. In Terraform we have the possibility to define something like an entrypoint on an EC2 instance which is called as soon as the EC2 instance is up and running. The according attribute is called `user_data`.

Add the following `user_data` block just before the `tags` attribute inside the `aws_instance` resource:

_main.tf_
```conf
    user_data = <<EOF
                    #!/bin/bash
                    sudo yum update -y && sudo yum install -y docker
                    sudo systemctl start docker
                    sudo usermod -aG docker ec2-user
                    docker run -p 8080:80 nginx
                EOF
```

Apply the changes:
```sh
terraform apply
# ...
# aws_instance.myapp-server: Modifying... [id=i-0994aec0c5300e204]
# aws_instance.myapp-server: Still modifying... [id=i-0994aec0c5300e204, 10s elapsed]
# aws_instance.myapp-server: Still modifying... [id=i-0994aec0c5300e204, 20s elapsed]
# aws_instance.myapp-server: Still modifying... [id=i-0994aec0c5300e204, 30s elapsed]
# aws_instance.myapp-server: Still modifying... [id=i-0994aec0c5300e204, 40s elapsed]
# aws_instance.myapp-server: Still modifying... [id=i-0994aec0c5300e204, 50s elapsed]
# aws_instance.myapp-server: Still modifying... [id=i-0994aec0c5300e204, 1m0s elapsed]
# aws_instance.myapp-server: Modifications complete after 1m1s [id=i-0994aec0c5300e204]
# 
# Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
# 
# Outputs:
# 
# aws_ami_id = "ami-08e415170f52d1657"
# ec2_public_ip = "3.67.138.246"
```

The server could be updated in-place. Open the browser and navigate to [http://3.67.138.246:8080](http://3.67.138.246:8080). You should see the nginx welcome page.

You can also ssh into the EC2 instance and execute `docker ps` to see the nginx container:
```sh
ssh ec2-user@3.67.138.246
docker ps
# CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS         PORTS                                   NAMES
# 30eafbc1406c   nginx     "/docker-entrypoint.…"   4 seconds ago   Up 3 seconds   0.0.0.0:8080->80/tcp, :::8080->80/tcp   laughing_spence
```

Note that the user_data script is executed just once when the EC2 instance was initialized. When you apply other changes that do not need to terminate the existing and re-create a new EC2 instance but instead can be applies in-place, the script will not get executed again.

### Extract to Shell Script
Instead of writing the whole script inside the user_data attribute, we can also extract it to a file and reference it just as we did before with the public key file:

_main.tf_
```conf
    user_data = file("entry-script.sh")
```

_entry-script.sh_
```sh
#!/bin/bash

# install and start docker
sudo yum update -y && sudo yum install -y docker
sudo systemctl start docker

# add ec2-user to docker group to allow it to call docker commands
sudo usermod -aG docker ec2-user

# start a docker container running nginx
docker run -p 8080:80 nginx
```

### Configuring Infrastructure not Servers
This last step of installing Docker and running nginx in it showed that Terraform is great for provisioning the infratructure but doesn't help much when it comes to deploying applications on the provisioned infrastructure. The only support is to provide an attribute that allows to execute normal shell scripts. So Terraform passes over the responsibility to you and shell scripting.

For tasks like deploying applications, configuring the server, installing or updating packages you better use configuration management tools like Chef, Puppet or Ansible.

</details>

*****
