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
```sh
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

```sh
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


</details>

*****