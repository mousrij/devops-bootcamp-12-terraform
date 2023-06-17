## Demo Project - Complete CI/CD with Terraform

### Topics of the Demo Project
Complete CI/CD with Terraform

### Technologies Used
- Terraform
- Jenkins
- Docker
- AWS
- Git
- Java
- Maven
- Linux
- Docker Hub

### Project Description
Integrate provisioning stage into complete CI/CD Pipeline to automate provisioning server instead of deploying to an existing server
- Create SSH Key Pair
- Install Terraform inside Jenkins container
- Add Terraform configuration to application’s git repository
- Adjust Jenkinsfile to add “provision” step to the CI/CD pipeline that provisions EC2 instance
- So the complete CI/CD project we build has the following configuration:
  - a. CI step: Build artifact for Java Maven application
  - b. CI step: Build and push Docker image to Docker Hub
  - c. CD step: Automatically provision EC2 instance using TF
  - d. CD step: Deploy new application version on the provisioned EC2 instance with Docker Compose

#### Steps to create an SSH Key Pair
We need to create a key-pair to be used by Jenkins to ssh/scp into the EC2 instance.

**Step 1:** Create Key-Pair on AWS
- Login to your AWS Management Console and navigate to the EC2 dashboard. 
- Click the "Key pairs" link and press "Create key pair".
- Enter the name 'myapp-key-pair', select the type ED25519 and the format .pem and press "Create key pair".
- A `myapp-key-pair.pem` file containing the private key is automatically downloaded. The public key is stored in AWS. When we create an EC2 instance with Terraform, we can associate the `myapp-key-pair` key in AWS with this instance.

**Step 2:** Store private key on Jenkins
- Move the `myapp-key-pair.pem` file from the download folder to the ssh folder and copy its content to the clipboard:
  ```sh
  mv ~/Downloads/myapp-key-pair.pem ~/.ssh/
  pbcopy < ~/.ssh/myapp-key-pair.pem
  ```
- Login to the Jenkins server and open the multibranch pipeline project for the java-maven-app (Dashboard > devops-bootcamp-multibranch-pipeline).
- Click on Credentials > Store devops-bootcamp-multibranch-pipeline > Global credentials (unrestricted) and press "+ Add Credentials".
- Select the kind "SSH Username with private key", enter the ID 'server-ssh-key' and the username 'ec2-user', select Private Key > Enter directly, press Key > Add, paste the private key from the clipboard and press "Create".

#### Steps to install Terraform inside Jenkins container
To install Terraform inside Jenkins container we have to ssh into the Droplet running the Jenkins container, enter the Jenkins container and execute the following commands:

```sh
# SSH into the Droplet running the Jenkins container
ssh root@64.225.104.226
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

#### Steps to add a Terraform configuration to application
Now we have to add Terraform configuration files to the java-maven-app project repository.

- Open the project and create a new branch called `sshagent-terraform`.
- Create a `terraform` folder containing a `main.tf` file with the following content (we reuse the file of demo project #1 and adjust it where necessary):
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
- Since we do not check in the `terraform.tfvars` file, we have to find another way of providing the variable values for the Jenkins pipeline. An easy way is to define default values for all the variables. Create a file `terraform/variables.tf` with the following content:
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
  Jenkins can override the default variable values by defining environment variables of the form `TF_VAR_variable_name`.
- Finally we copy the file `entry-script.sh` we created in demo project #1 into the `terraform` folder. However, instead of running an nginx container (last command), we install docker-compose, because in the project's Jenkinsfile we upload a docker-compose.yaml to the remote server and execute it with docker-compose. So we replace the last command with two commands installing docker-compose and setting executable permission (see [Install Docker Compose](https://docs.docker.com/compose/install/standalone/)). The final `entry-script.sh` file looks like this:
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

#### Steps to add a “provision” stage to the CI/CD pipeline that provisions an EC2 instance
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
                EC2_PUBLIC_IP = sh(
                    script: "terraform output ec2_public_ip",
                    returnStdout: true
                ).trim()
            }
        }
    }
}
```

The first two environment variables are needed to authenticate Jenkins server against AWS. We reuse credentials created in a previous video. The third environment variable is just here to demonstrate how we can override the default values defined in the `variables.tf` file.

After the `terraform apply` command we store the IP address of the provisioned EC2 instance in an environment variable because we need it in the following "Deploy" stage.

#### Steps to adjust the "Deploy" stage
Replace the existing "Deploy Application" stage with the following content:

```groovy
stage('Deploy Application') {
    environment {
        DOCKER_CREDS = credentials('DockerHub')
    }
    steps {
        script {
            echo "waiting for EC2 server to initialize" 
            sleep(time: 90, unit: "SECONDS") 

            echo 'deploying Docker image to EC2 server...'
            echo "${EC2_PUBLIC_IP}"

            def shellCmd = "bash ./server-cmds.sh ${IMAGE_TAG} ${DOCKER_CREDS_USR} ${DOCKER_CREDS_PSW}"
            def ec2Instance = "ec2-user@${EC2_PUBLIC_IP}"

            sshagent(['server-ssh-key']) {
                sh "scp -o StrictHostKeyChecking=no server-cmds.sh docker-compose.yaml ${ec2Instance}:/home/ec2-user"
                sh "ssh -o StrictHostKeyChecking=no ${ec2Instance} ${shellCmd}"
            }
        }
    }
}
```

When the EC2 instance is created, the `terraform apply` command returns and the "Provision Server" stage is done. However, the EC2 instance has not been initialized yet. The commands in `entry-script.sh` are still being executed. This means that docker-compose might not be available when the "Deploy Application" stage starts. The easiest way to solve this issue is to pause the pipeline execution for a certain duration until we can expect the initialization process to have finished.

Of course this is not an ideal solution because it slows down the pipeline. The sleep is only necessary during the first pipeline run. During the following runs the EC2 instance is already up and running and does not have to be initialized anymore.

When the `docker-compose` command is executed on the EC2 instance, the Docker image of the java-maven-app has to be pulled from the private registry on Docker Hub. So the EC2 instance has to login to this private registry. We add the `docker login` command to the `server-cmds.sh` script that is copied to the EC2 instance and executed there:

```sh
#!/usr/bin/env/ bash

export IMAGE_TAG=$1
export DOCKER_USER=$2 # <--
export DOCKER_PWD=$3  # <--
echo $DOCKER_PWD | docker login -u $DOCKER_USER --password-stdin  # <--
docker-compose -f docker-compose.yaml up -d
echo "successfully started the containers using docker-compose"
```

We have to pass two additional parameters to the script: the username and password of the private Docker Hub registry. In the Jenkinsfile this is done by assigning the DockerHub credentials to an environment variable 'DOCKER_CREDS', which implicitly creates two other environment variables 'DOCKER_CREDS_USR' and 'DOCKER_CREDS_PSW'.

#### Steps to run the pipeline
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

Because we have configured the multibranch pipeline on Jenkins to build all the branches, the new branch will be detected and the first pipeline build will be triggered automatically.

After the build finished, we check the logs to get the IP address of the newly provisioned EC2 instance. Then we ssh into this EC2 instance and check whether a docker container with the java-maven-app is running:

```sh
chmod 400 ~/.ssh/myapp-key-pair.pem
ssh -i ~/.ssh/myapp-key-pair.pem ec2-user@3.76.7.164
docker ps
# CONTAINER ID   IMAGE                                                         COMMAND                  CREATED          STATUS          PORTS                                       NAMES
# 459bc9f7af12   fsiegrist/fesi-repo:devops-bootcamp-java-maven-app-1.0.57-7   "/bin/sh -c 'java -j…"   53 seconds ago   Up 52 seconds   0.0.0.0:8000->8080/tcp, :::8000->8080/tcp   ec2-user-java-maven-app-1
```

Open the browser and navigate to 'http://3.76.7.164:8000' to see the java-maven-app in action.
