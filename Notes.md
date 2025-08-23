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
terraform apply --auto-approve
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
terraform destroy --auto-approve
terraform apply --auto-approve
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
- create a Security Group (firewall)
- provision EC2 instance
- deploy nginx Docker container

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
terraform apply --auto-approve
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

Following the best practice, we don't add a route to the route table automatically created by AWS, but we create a new Route Table containing the two entries we need. The entry concerning the traffic of the VPC IP range (with Target = local) is created for each route table and cannot be created manually (or by Terraform). So we only have to define an entry for the internet connectivity. Add the following resources to the main.tf file:

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
terraform apply --auto-approve
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

Add the following resource to the configuration file:

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
First of all we need an Amazon Machine Image (AMI) which will be used as a template for the EC2 virtual machine. We could go to the AWS Management Console and look up the id of the AMI we want to use. But this id may change when Amazon updates the image. So instead of hardcoding it into the configuration file, we define a `data` querying the latest version of the image we want to use (the AMI name can be found in EC2 > AMI Catalog > Community AMIs):

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
Creating the key pair was a manual step. We should try to automate as many steps as possible. So let's use an existing key pair we created on our local machine and copy the public key to the EC2 instance. If you haven't created a private/public key-pair yet, execute `ssh-keygen -t ed25519` to do so.

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
To create new ssh key with the convenient technique:

```sh
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

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

The server could be updated in-place. Open the browser and navigate to `http://3.67.138.246:8080`. You should see the nginx welcome page.

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

<details>
<summary>Video: 15 - Provisioners in Terraform</summary>
<br />

As soon as the EC2 instance has been created, the Terraform `apply` command returns. It doesn't wait for any initialization scripts passed over via `user_data` to finish, nor does it report any errors that occured during script execution.

To have more control over commands executed on a remote server you can use provisioners. There are three different provisioners:
- `file`: copy a file from local machine to remote server
- `remote-exec`: execute commands / a script on a remote server
- `local-exec` execute commands / a script on the local machine

If you use one of `file` or `remote-exec` you need to connect to the remote server. The connection is established using a `connection` block.

To get an idea of how to use these entities, study the following self-explanatory examples:

```conf
connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_location)
}

provisioner "file" {
    source = "entry-script.sh"
    destination = "/home/ec2-user/entry-script-on-ec2.sh"
}

provisioner "remote-exec" {
    script = file("entry-script-on-ec2.sh")
}

provisioner "local-exec" {
    command = "echo ${self.public_ip} > output.txt"
}
```

However, provisioners are NOT recommended by Terraform. They break the concept of idempotency because they are eexecuted only once when the EC2 instance is initialized. And because Terraform doesn't know what your scripts are doing, using the remote-exec provisioner also breaks the comparison between current and desired state.

A better way of doing these kind of tasks is using configuration management tools like Ansible. So hand over the process to those tools once the server is provisioned.

Of course you can also upload and execute scripts from the CI/CD pipeline, as we did in the previous modules.

An alternative for using the `local-exec`provisioner is the provider called 'local' that is maintained by Hashicorp and can detect changes between the current state and the desired state. See its documentation [here](https://registry.terraform.io/providers/hashicorp/local/latest/docs).

</details>

*****

<details>
<summary>Video: 16 - Modules in Terraform - Part 1</summary>
<br />

Modules are container for multiple resources, used together. They help you organize and group your configuration files. Modules let you customize the configuration with input variables and access output values like created resources or specific attributes. Like this you can easily reuse the same configuration, e.g. for different AWS regions.

You can either use existing modules from the [Terraform registry](https://registry.terraform.io/browse/modules), or create your own ones, just to clean up your code. For each existing module you'll find a description of the possible input and output values, the dependencies (to other modules or providers), the resources that may be created by the module, as well as provision instructions.

</details>

*****

<details>
<summary>Video: 17 - Modules in Terraform - Part 2</summary>
<br />

### Modularize our Project
Let's divide our configuration file _terraform/main.tf_ into multiple reusable modules. It's a good practice to move the variable definitions into their own _variables.tf_ file, the outputs into an _outputs.tf_ file and the providers into a _providers.tf_ file. In the _main.tf_ file you will keep only the resources and data definitions.

We don't have to cross-reference these files. Terraform just collects everything from the various `.tf` files it finds in the project folder. You can also give the files whatever names you like, however the mentioned names are just common practice.

So we end up with a file

_terraform/variables.tf_
```conf
variable env_prefix {}
variable avail_zone {}
variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable my_ip {}
variable instance_type {}
variable public_key_location {}
```

a file

_/terraform/outputs.tf_
```conf
output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
}

output "ec2_public_ip" {
    value = aws_instance.myapp-server.public_ip
}
```

and a file _terraform/main.tf_ containing all the rest. Since we have just one provider we don't extract it into its own file.

### Create Modules
To create modules we first create a folder called `modules` and within that folder a folder for each module, e.g. one folder called `webserver` and a second one called `subnet`. And each module gets its own `main.tf`, `variables.tf` and `outputs.tf` files.

```sh
mkdir modules

mkdir modules/webserver
touch modules/webserver/main.tf
touch modules/webserver/variables.tf
touch modules/webserver/outputs.tf

mkdir modules/subnet
touch modules/subnet/main.tf
touch modules/subnet/variables.tf
touch modules/subnet/outputs.tf
```
the hierarchical folder architechture 
<img src="/img/image.png" />
This is the structure of modules in Terraform. Child modules are referenced by another module
on a higher level.

First let's extract the subnet related resources from the _terraform/main.tf_ file into the _terraform/modules/subnet/main.tf_ file. All the references to resources in the parent module have to be replaced by references to variables. And these variables have to be declared in the child module's _variables.tf_ file together with all the other variables referenced by the child module:

_terraform/modules/subnet/main.tf_
```conf
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = var.vpc_id                   # was aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name = "${var.env_prefix}-subnet-1"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = var.vpc_id                   # was aws_vpc.myapp-vpc.id
    tags = {
        Name = "${var.env_prefix}-igw"
    }
}

resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = var.default_route_table_id  # was aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id  # doesn't have to be replaced by a variable since it references a resource inside the same module
    }
    tags = {
        Name = "${var.env_prefix}-main-rtb"
    }
}
```

_terraform/modules/subnet/variables.tf_
```conf
variable env_prefix {}
variable avail_zone {}
variable subnet_cidr_block {}
variable vpc_id {}                  # new variable defined here
variable default_route_table_id {}  # new variable defined here
```

### Use the Module
To reference the new child module from the root module, the root module uses a `module` block:

_terraform/main.tf_
```conf
module "myapp-subnet" {
  source = "./modules/subnet"

  env_prefix = var.env_prefix
  avail_zone = var.avail_zone
  subnet_cidr_block = var.subnet_cidr_block
  vpc_id = aws_vpc.myapp-vpc.id
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
}
```

As you see, the variables for the child module are not defined in a _terraform.tfvars_ file of the child module but have to be passed from the root module to the child module by adding them as attributes inside the `module` block.

### Module Output
At this point the references in the root module to other resources that now have been moved to a child module (e.g. `subnet_id = aws_subnet.myapp-subnet-1.id` in the `aws_instance.myapp-server` resource) are broken.

In order to fix these references, the child module has to output the required resources and the root module has to reference them. So first let the child module output the subnet resource:

_terraform/modules/subnet/outputs.tf_
```conf
output "subnet" {
  value = aws_subnet.myapp-subnet-1
}
```

Now we can reference the output as follows:

_terraform/main.tf_
```conf
resource "aws_instance" "myapp-server" {
  ...
  subnet_id = module.myapp-subnet.subnet.id   # was aws_subnet.myapp-subnet-1.id
  ...
}
```

### Apply Configuration Changes
Whenever a module was created or changed we have to execute `terraform init` in order to reinitialize the working directory. Only then you can execute `terraform apply`.

```sh
terraform init
terraform plan
terraform apply --auto-approve
```

</details>

*****

<details>
<summary>Video: 18 - Modules in Terraform - Part 3</summary>
<br />

### Create "webserver" Module
Let's repeat the same steps to extract a "webserver" module responsible for creating an EC2 instance. First move the security group "default-sg", the AMI data "latest-amazon-linux-image", the key-pair "ssh-key" and the instance "myapp-server" from the root _main.tf_ file to the _modules/webserver/main.tf_ file. Then extract variables for elements to be passed in by the root module or for elements you think would make sense to be configurable for a module creating an EC2 instance (e.g. the ami name). Note that you cannot reference sibling modules. This results in the following files:

_terraform/modules/webserver/main.tf_
```conf
resource "aws_default_security_group" "default-sg" {
  vpc_id = var.vpc_id    # was aws_vpc.myapp-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ...

  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = [var.image_name]    # was "amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id = var.subnet_id    # was module.myapp-subnet.subnet.id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

  user_data = file("entry-script.sh")   # note that file paths are relative to the root module

  tags = {
    Name = "${var.env_prefix}-server"
  }
}
```

_terraform/modules/webserver/variables.tf_
```conf
variable env_prefix {}
variable avail_zone {}
variable my_ip {}
variable instance_type {}
variable public_key_location {}
variable vpc_id {}
variable image_name {}
variable subnet_id {}
```

Now we can reference the new module from within the root module's configuration file:

_terraform/main.tf_
```conf
module "myapp-server" {
  source = "./modules/webserver"
  
  env_prefix = var.env_prefix
  avail_zone = var.avail_zone
  vpc_id = aws_vpc.myapp-vpc.id
  subnet_id = module.myapp-subnet.subnet.id
  my_ip = var.my_ip
  image_name = var.image_name
  public_key_location = var.public_key_location
  instance_type = var.instance_type
}
```

As we introduced a new variable `image_name` we have to add it to the file _terraform/variables.tf_ and set its value in the file _terraform/terraform.tfvars_:

_terraform/variables.tf_
```conf
variable env_prefix {}
variable avail_zone {}
variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable my_ip {}
variable image_name {}   # <---
variable instance_type {}
variable public_key_location {}
```

_terraform/terraform.tfvars_
```conf
env_prefix = "dev"
avail_zone = "eu-central-1a"
vpc_cidr_block = "10.0.0.0/16"
subnet_cidr_block = "10.0.10.0/24"
my_ip = "31.10.152.229/32"
image_name = "amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"   # <---
instance_type = "t2.micro"
public_key_location = "/Users/fsiegrist/.ssh/id_ed25519.pub"
```

And finally we have to adjust the outputs. The references in the root module's _outputs.tf_ file are broken. We have to output the required resources in the child module (webserver) and reference these outputs in the root module:

_terraform/modules/webserver/outputs.tf_
```conf
output "instance" {
    value = aws_instance.myapp-server
}
```

_terraform/outputs.tf_
```conf
output "ec2_public_ip" {
    value = module.myapp-server.instance.public_ip
}
```

Now we can apply the chages. Again we have to execute `terraform init` first:

```sh
terraform init
terraform plan
terraform apply --auto-aprove
```

</details>

*****

<details>
<summary>Video: 19 - Automate Provisioning EKS cluster with Terraform - Part 1</summary>
<br />

Until now we created an EKS cluster manually on the AWS Management Console and then using the command line tool `eksctl`. But either way was rather complex because there are quite a few compontents to be created and configured. And we don't have a history of what we did (e.g. in a version control system), a simple replication of the infrastructure in another environment isn't possible, the collaboration in a team is difficult (if many developers are working on the configuration of the cluster) and finally there is no simple way of cleaning up the whole cluster when we don't need it anymore.

All these aspects make provisioning an EKS cluster using Terraform the currently best and most efficient way to do so.

Let's recap what needs to be done to setup an EKS cluster:
- create a Control Plane (the EKS service itself)
- create a VPC for the Worker Nodes
- create a group of Worker Nodes (EC2 instances) in all the Availability Zones of the current region and connect them with the Control Plane

### VPC
We configured the VPC to be used for EKS with the Cloudformation template. Cloudformation is a provisioning alternative for Terraform but specific to AWS. We cannot use the Cloudformation template in Terraform but we can use an existing Terraform module provisioning a VPC suitable for use with EKS.

Open the browser, navigate to [Terraform AWS modules (VPC)](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest?tab=resources), copy the configuration snippet in the "Provision Instructions" box and paste it into a file called `vpc.tf` in the `terraform` folder:

_terraform/vpc.tf_
```conf
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
}
```

The module gets downloaded when `terraform init` is executed.

Now we have to define at least the required attributes for the module. Since this module does not have any required attributes we can choose which of the optional ones we want to define. The final `vpc.tf` file will then look like this:

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

Now we can initialize the Terraform project and validate it to see if our configuration is syntactically correct so far:

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

Everything seems to be ok. But before we apply it, we need to create the EKS and other resources (see next video).

</details>

*****

<details>
<summary>Video: 20 - Automate Provisioning EKS cluster with Terraform - Part 2</summary>
<br />

### EKS Cluster and Worker Nodes
Again we use an existing module to provision the EKS cluster. Open the browser, navigate to [Terraform AWS modules (EKS)](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest), copy the configuration snippet in the "Provision Instructions" box and paste it into a file called `eks-cluster.tf` in the `terraform` folder:

_terraform/eks-cluster.tf_
```conf
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.2"
}
```

Again we set attributes for which we want to configure special values and end up with the following configuration file:

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

### Apply the Configuration Files
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

</details>

*****

<details>
<summary>Video: 21 - Automate Provisioning EKS cluster with Terraform - Part 3</summary>
<br />

### EKS Cluster Overview
Login to your AWS Management Console and check all the resources that have been created:
- EKS (Cluster, Node Group, Kubernetes resources, etc.)
- IAM (Roles)
- EC2 (3 Nodes)
- VPC (Route Tables, Internet Gateway, Subnets, Security Groups)

### Deploy nginx-App into our Cluster
Prerequisites to connect to the cluster with kubectl:
- AWS CLI installed
- kubectl installed
- aws-iam-authenticator installed

Update the kubeconfig file executing the follwoing command:
```sh
aws eks update-kubeconfig --name myapp-eks-cluster --region eu-central-1
# Added new context arn:aws:eks:eu-central-1:369076538622:cluster/myapp-eks-cluster to /Users/fsiegrist/.kube/config
```

Now we are connected with our cluster:
```sh
kubctl get nodes
# NAME                                          STATUS   ROLES    AGE   VERSION
# ip-10-0-1-237.eu-central-1.compute.internal   Ready    <none>   38m   v1.27.1-eks-2f008fe
# ip-10-0-2-163.eu-central-1.compute.internal   Ready    <none>   38m   v1.27.1-eks-2f008fe
# ip-10-0-3-28.eu-central-1.compute.internal    Ready    <none>   38m   v1.27.1-eks-2f008fe

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

Open the browser and navigate to 'http://a8052fa527f3f4ffd8833a94039e849f-1687828084.eu-central-1.elb.amazonaws.com'. You should see the nginx welcome page.

You can find this URL also in the AWS Management Console > EC2 Dashboard > Load Balancers, select the load balancer in the list, open the "Description" tab and copy the DNS name from the "Basic Configuration" section.

### Destroy all Components
When you're done with the cluster you can very easily remove all the resources by executing `terraform destroy`. But because we deployed a LoadBalancer service, a cloud-native LoadBalancer has been created Terraform doesn't know about. The subnets created by Terraform cannot be destroyed as long as the network interfaces are in use by the LoadBalancer. So we first have to undeploy the LoadBalancer service.

```sh
kubectl delete -f ../k8s/nginx-config.yaml

terraform destroy --auto-approve
# ...
# Plan: 0 to add, 0 to change, 55 to destroy.
# module.vpc.aws_route_table_association.public[2]: Destroying... [id=rtbassoc-012dec7f3fb951ae9]
# module.vpc.aws_default_route_table.default[0]: Destroying... [id=rtb-06b8ef065f1300183]
# ...
# module.eks.module.eks_managed_node_group["dev"].aws_eks_node_group.this[0]: Destruction complete after 6m21s
# ...

terraform state list
# should return nothing
```

</details>

*****

<details>
<summary>Video: 22 - Complete CI/CD with Terraform - Part 1</summary>
<br />

### CI/CD with Terraform
Instead of manually creating an EC2 instance before running the Jenkins pipeline to build an application and deploy it on this EC2 instance, we want to integrate Terraform into the build pipeline and provision the EC2 server as part of the build pipeline.

In order to do so, we need to
- create a key-pair to be used by Jenkins to ssh/scp into the EC2 instance,
- install Terraform inside the Jenkins container
- add Terraform configuration files to the project
- adjust the Jenkinsfile.

</details>

*****

<details>
<summary>Video: 23 - Complete CI/CD with Terraform - Part 2</summary>
<br />

### Create SSH Key-Pair
Login to your AWS Management Console and navigate to the EC2 dashboard. Click the "Key pairs" link and press "Create key pair". Enter a name (e.g. myapp-key-pair), select the type ED25519 and the format .pem and press "Create key pair". A `myapp-key-pair.pem` file containing the private key is automatically downloaded. The public key is stored in AWS. When we create an EC2 instance with Terraform, we can associate the `myapp-key-pair` key in AWS with this instance.

Now we have to store this private key on Jenkins server. First move the .pem file from the download folder to the ssh folder and copy its content to the clipboard:

```sh
mv ~/Downloads/myapp-key-pair.pem ~/.ssh/
pbcopy < ~/.ssh/myapp-key-pair.pem
```

Now login to your Jenkins server and open the multibranch pipeline project for the java-maven-app (Dashboard > devops-bootcamp-multibranch-pipeline). Click on Credentials > Store devops-bootcamp-multibranch-pipeline > Global credentials (unrestricted) and press "+ Add Credentials". Select the kind "SSH Username with private key", enter an ID (e.g. server-ssh-key), the username is 'ec2-user', select Private Key > Enter directly, press Key > Add, paste the private key from the clipboard and press "Create".

### Install Terraform inside Jenkins Container
To install Terraform inside Jenkins container we have to ssh into the Droplet running the Jenkins container, enter the Jenkins container and execute the following commands:

```sh
# SSH into the Droplet running the Jenkins container
ssh root@<jenkins-droplet-ip>
# => root@jenkins-server:~#

# get the Jenkins container ID
docker ps
# CONTAINER ID   IMAGE                 COMMAND                  CREATED        STATUS       PORTS                                                                                      NAMES
# 54ae5b80a7c8   jenkins/jenkins:lts   "/usr/bin/tini -- /u…"   2 months ago   Up 2 weeks   0.0.0.0:8080->8080/tcp, :::8080->8080/tcp, 0.0.0.0:50000->50000/tcp, :::50000->50000/tcp   nervous_euler

# enter the Jenkins container
docker exec -it -u 0 54ae5b80a7c8 bash
# => root@54ae5b80a7c8:/#

# find out which Linux distribution is running
cat /etc/os-release
# PRETTY_NAME="Debian GNU/Linux 11 (bullseye)"
# NAME="Debian GNU/Linux"
# VERSION_ID="11"
# VERSION="11 (bullseye)"
# VERSION_CODENAME=bullseye
# ID=debian
# HOME_URL="https://www.debian.org/"
# SUPPORT_URL="https://www.debian.org/support"
# BUG_REPORT_URL="https://bugs.debian.org/"

# find the installation instructions for Linux Debian on 'https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli'

# install needed tools
apt-get update && apt-get install -y gnupg software-properties-common wget

# install the HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

# verify the key's fingerprint
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint
# /usr/share/keyrings/hashicorp-archive-keyring.gpg
# -------------------------------------------------
# pub   rsa4096 2023-01-10 [SC] [expires: 2028-01-09]
#       798A EC65 4E5C 1542 8C8E  42EE AA16 FCBC A621 E701
# uid           [ unknown] HashiCorp Security (HashiCorp Package Signing) <security+packaging@hashicorp.com>
# sub   rsa4096 2023-01-10 [S] [expires: 2028-01-09]

# add the official HashiCorp repository to your system
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
tee /etc/apt/sources.list.d/hashicorp.list

# download the package information from HashiCorp
apt update

# install Terraform from the new repository
apt-get install terraform

# check
terraform -v
# Terraform v1.4.6
# on linux_amd64
```

### Terraform Configuration Files
Now we have to add Terraform configuration files to the java-maven-app project repository. Open the project and create a new branch called `sshagent-terraform`. Create a `terraform` folder containing a `main.tf` file and copy the content of the configuration file created in video 12-14 (or in demo project #1) to this `main.tf` file. We can remove the resource "aws_key_pair.ssh-key" because we manually created a key-pair. In the resource "aws_instance.myapp-server" we replace the "key_name" attribute value `aws_key_pair.ssh-key.key_name` (referencing the deleted resource) with the hardcoded name of the manually created key-pair (`"myapp-key-pair"`). We also delete the variable `public_key_location`.

Since we do not check in the `terraform.tfvars` file, we have to find another way of providing the variable values for the Jenkins pipeline. An easy way is to define default values for all the variables. So lets move all the variables from the `main.tf` file into their own separate file `variables.tf`. And instead of just defining the variable names, we now also define a default value for each variable. We end up with a `variables.tf` file with the following content:

```conf
variable env_prefix {
    default = "dev"
}
variable region {
    default = "eu-central-1"
}
variable avail_zone {
    default = "eu-central-1a"
}
variable vpc_cidr_block {
    default = "10.0.0.0/16"
}
variable subnet_cidr_block {
    default = "10.0.10.0/24"
}
variable my_ip {
    default = "31.10.152.229/32"
}
variable jenkins_ip {
    default = "64.225.104.226/32"
}
variable instance_type {
    default = "t2.micro"
}
```

Now Jenkins does not have to provide any variable values, as long as the default values are ok. Of course we can override each value by providing a `terraform.tfvars` file with the variable values to be overridden. Jenkins can override the default variable values by defining environment variables of the form `TF_VAR_variable_name`.

The final `main.tf` file looks like this:

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
  region = var.region
}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix}-vpc"
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

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name = "${var.env_prefix}-igw"
    }
}

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

resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip, var.jenkins_ip]
    }

    ingress {
        from_port = 8000
        to_port = 8000
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

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = "myapp-key-pair"

    user_data = file("entry-script.sh")

    tags = {
        Name = "${var.env_prefix}-server"
    }
}

output "ec2_public_ip" {
    value = aws_instance.myapp-server.public_ip
}
```

Finally we have to copy the file `entry-script.sh` we created in video 12-14 (or in demo project #1). However, instead of running an nginx container (last command), we install docker-compose, because in the project's Jenkinsfile we upload a docker-compose.yaml to the remote server and execute it with docker-compose. So we replace the last command with two commands installing docker-compose and setting executable permission (see [Install Docker Compose](https://docs.docker.com/compose/install/standalone/)). The final `entry-script.sh` file looks like this:

```sh
#!/bin/bash

# install and start docker
sudo yum update -y && sudo yum install -y docker
sudo systemctl start docker

# add ec2-user to docker group to allow it to call docker commands
sudo usermod -aG docker ec2-user

# install docker-compose 
sudo curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Provision Stage in Jenkinsfile
Now we can add a stage to the pipeline which provisions an EC2 instance by executing terraform commands. Add the following stage definition to the Jenkinsfile right after the "Build and Publisch Docker Image" stage:

```groovy
stage('Provision Server') {
    environment {
        AWS_ACCESS_KEY_ID = credentials('jenkins-aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws_secret_access_key')
        TF_VAR_env_prefix = 'test'
    }
    steps {
        script {
            dir('terraform') {
                sh "terraform init"
                sh "terraform apply --auto-approve"
            }
        }
    }
}
```

The first two environment variables are needed to authenticate Jenkins server against AWS. We reuse credentials created in a previous video. The third environment variable is just here to demonstrate how we can override the default values defined in the `variables.tf` file.

### Deploy Stage in Jenkinsfile
The "Deploy Application" stage we wrote in module 9 (AWS Services) looked like this:

```groovy
stage('Deploy Application') {
    steps {
        script {
            echo 'deploying Docker image to EC2 server...'
            def shellCmd = "bash ./server-cmds.sh ${IMAGE_TAG}"
            sshagent(['ec2-server-key']) {
                sh 'scp -o StrictHostKeyChecking=no server-cmds.sh docker-compose.yaml ec2-user@35.156.226.244:/home/ec2-user'
                sh "ssh -o StrictHostKeyChecking=no ec2-user@35.156.226.244 ${shellCmd}"
            }
        }
    }
}
```

Now we can no longer hardcode the IP address of the EC2 instance, since a new EC2 instance is created by the "provision Server" stage during the first pipeline run. So we have to reference the output "ec2_public_ip" of the terraform `main.tf` configuration file. A possible way to achieve this is to store the value in an environment variable. We add the following command to the script of the "Provision Server" stage:

```groovy
script {
    dir('terraform') {
        sh "terraform init"
        sh "terraform apply --auto-approve"
        EC2_PUBLIC_IP = sh(
            script: "terraform output ec2_public_ip",
            returnStdout: true
        ).trim()
    }
}
```

We then can access this variable in the "Deploy Application" stage:

```groovy
def ec2Instance = "ec2-user@${EC2_PUBLIC_IP}"

sshagent(['server-ssh-key']) {
  sh "scp -o StrictHostKeyChecking=no server-cmds.sh docker-compose.yaml ${ec2Instance}:/home/ec2-user"
  sh "ssh -o StrictHostKeyChecking=no ${ec2Instance} ${shellCmd}"
}
```

Note that we also switched to the new key-pair name 'server-ss-key'.

Another problem is that when the EC2 instance is created, the `terraform apply` command returns and the "Provision Server" stage is done. However, the EC2 instance has not been initialized yet. The commands in `entry-script.sh` are still being executed. This means that docker-compose might not be available when the "Deploy Application" stage starts. The easiest way to solve this issue is to pause the pipeline execution for a certain duration until we can expect the initialization process to have finished. Let's add the following commands to the beginning of the script in the "Deploy Application" stage:

```groovy
echo "waiting for EC2 server to initialize" 
sleep(time: 90, unit: "SECONDS") 

echo 'deploying Docker image to EC2 server...'
echo "${EC2_PUBLIC_IP}"
```

Of course this is not an ideal solution because it slows down the pipeline. The sleep is only necessary during the first pipeline run. During the following runs the EC2 instance is already up and running and does not have to be initialized anymore.

</details>

*****

<details>
<summary>Video: 24 - Complete CI/CD with Terraform - Part 3</summary>
<br />

### Docker Login Required to Pull Docker Image
When the docker-compose command is executed on the EC2 instance, the Docker image of the java-maven-app has to be pulled from the private registry on Docker Hub. So the EC2 instance has to login to this private registry. In module 09 (AWS Services) we ssh-ed into the manually created EC2 instance and manually executed the `docker login` command. But now we want to automate this process and add the `docker login` command to the `server-cmds.sh` script that is copied to the EC2 instance and executed there:

```sh
#!/usr/bin/env/ bash

export IMAGE_TAG=$1
export DOCKER_USER=$2 # <--
export DOCKER_PWD=$3  # <--
echo $DOCKER_PWD | docker login -u $DOCKER_USER --password-stdin  # <--
docker-compose -f docker-compose.yaml up -d
echo "successfully started the containers using docker-compose"
```

We have to pass two additional parameters to the script: the username and password of the private Docker Hub registry. In the Jenkinsfile this is done as follows:

```groovy
stage('Deploy Application') {
    environment {
        DOCKER_CREDS = credentials('DockerHub')  // <-- this command implicitly creates two environment variables DOCKER_CREDS_USR and DOCKER_CREDS_PSW
    }
    steps {
        script {
            echo "waiting for EC2 server to initialize" 
            sleep(time: 90, unit: "SECONDS") 

            echo 'deploying Docker image to EC2 server...'
            echo "${EC2_PUBLIC_IP}"

            def shellCmd = "bash ./server-cmds.sh ${IMAGE_TAG} ${DOCKER_CREDS_USR} ${DOCKER_CREDS_PSW}"  // <-- use the implicitly created environment variables
            def ec2Instance = "ec2-user@${EC2_PUBLIC_IP}"

            sshagent(['server-ssh-key']) {
                sh "scp -o StrictHostKeyChecking=no server-cmds.sh docker-compose.yaml ${ec2Instance}:/home/ec2-user"
                sh "ssh -o StrictHostKeyChecking=no ${ec2Instance} ${shellCmd}"
            }
        }
    }
}
```

### Run the Pipeline
Because we created a new branch `feature/sshagent-terraform` we have to adjust the branch name in the final "Commit Version Update" stage:

```groovy
sh 'git push origin HEAD:feature/sshagent-terraform'
```

Now we can commit and push all the changes to the project repository:

```sh
git add .
git commit -m "Deploy on ec2 instance provisioned using terraform"
git push -u origin feature/sshagent-terraform
```

If we have configured the multibranch pipeline on Jenkins to build all the branches, the new branch will be detected and the first pipeline build will be triggered automatically.

After the build finished check the logs to get the IP address of the newly provisioned EC2 instance. SSH into this EC2 instance and check whether a docker container with the java-maven-app is running:

```sh
chmod 400 ~/.ssh/myapp-key-pair.pem
ssh -i ~/.ssh/myapp-key-pair.pem ec2-user@<ip-address-copied-from-jenkins-log>
docker ps
# CONTAINER ID   IMAGE                                                         COMMAND                  CREATED          STATUS          PORTS                                       NAMES
# 459bc9f7af12   fsiegrist/fesi-repo:devops-bootcamp-java-maven-app-1.0.57-7   "/bin/sh -c 'java -j…"   53 seconds ago   Up 52 seconds   0.0.0.0:8000->8080/tcp, :::8000->8080/tcp   ec2-user-java-maven-app-1
```

Open the browser and navigate to 'http://<ip-address-copied-from-jenkins-log>:8000' to see the java-maven-app in action.

</details>

*****

<details>
<summary>Video: 25 - Remote State in Terraform</summary>
<br />

When working with Terraform in a team you might want to share the state and be sure everyone works on the same state. Instead of using a local state file on every machine executing terraform commands, it is possible to configure a remote state file. There are different remote storage options available.

### Configure Remote Storage
Inside a Terraform configuration file you can define a `terraform` block having different attributes one of which is the `backend` attribute defining the state storage. The default value is "local", which stores the state data in a local file called `terraform.tfstate`.

With "remote" backend, Terraform writes the state data to a remote data store, which can then be shared between all members of a team. Terraform supports storing state in Terraform Cloud, HashiCorp Consul, Amazon S3, Azure Blob Storage, Google Cloud Storage, Alibaba Cloud OSS, and more.

As an example we configure the usage of an Amazon S3 file storage:

```conf
terraform {
  required_version = ">= 1.2.0"
  backend "s3" {
    bucket = "my-devops-bootcamp-tfstate-bucket"
    key = "myapp/state.tfstate"
    region = "eu-central-1"
  }
}
```

To use this storage we first have to create the bucket on AWS.

### Create AWS S3 Bucket
Login to your AWS Management Console and navigate to Services > Storage > S3. The current region automatically switches to "Global". Press "Create bucket", enter the bucket name "my-devops-bootcamp-tfstate-bucket" (must be a name which is unique in the global namespace), select your region (e.g. eu-central-1), enable Bucket Versioning and leave all the other options unchanged. Press "Create bucket". Clicking on the newly created bucket opens it, but there are no objects stored yet.

When we commit our changes to the configuration file and thus trigger a new build of the multibranch pipeline, the first version of the remote state file will be creates by Jenkins. If the `terraform init` command fails because it prompts whether the existing local state should be migrated to the new S3 remote state, you may have to enter the Jenkins workspace and manually delete the local state file:

```sh
ssh root@<jenkins-droplet-ip>
docker exec -it <jenkins-container-id> bash
cd /var/jenkins_home/workspace/<pipeline>/terraform
rm terraform.tfstate
rm terraform.tfstate.backup
exit
exit
```

Then you can trigger a new pipeline build via Jenkins UI.

If you want to use this state file from your local machine, you have to execute
```sh
terraform init
# Initializing the backend...
# 
# Successfully configured the backend "s3"! Terraform will automatically
# use this backend unless the backend configuration changes.
# ...

terraform state list # <-- connects to the s3 bucket and reads the current state from there
# data.aws_ami.latest-amazon-linux-image
# aws_default_route_table.main-rtb
# aws_default_security_group.default-sg
# aws_instance.myapp-server
# aws_internet_gateway.myapp-igw
# aws_subnet.myapp-subnet-1
# aws_vpc.myapp-vpc
```

</details>

*****

<details>
<summary>Video: 26 - Terraform Best Practices</summary>
<br />

### Best Practices Around Terraform State
- Manipulate state only through TF commands, don't manually change the state file
- Always set up a shared remote state instead of on your laptop or in Git
- Use state locking (locks state file until writing of state file is completed); be aware that not all remote backends support locking
- Back up your state file and enable versioning (allows for state recovery)
- Use 1 state per environment

### Other Best Practices
- Host TF scripts in Git repository
- CI for TF code (review TF code, run automated tests)
- Apply TF ONLY through CD pipeline (instead of manually)
- Use _ (underscore) instead of - (dash) in all resource names, data source names, variable names, outputs etc.
- Only use lowercase letters and numbers
- Use a consistent structure and naming convention
- Don’t hardcode values as much as possible - pass as variables or use data sources to get a value

</details>

*****
