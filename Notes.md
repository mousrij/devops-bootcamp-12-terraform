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


