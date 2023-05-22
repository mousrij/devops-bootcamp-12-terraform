## Exercises for Module 12 "Infrastructure as Code with Terraform"
<br />

Your K8s cluster on AWS is successfully running and used as a production environment. Your team wants to have additional K8s environments for development, test and staging with the same exact configuration and setup, so they can properly test and try out new features before releasing to production. So you must create 3 more EKS clusters.

But you don't want to do that manually 3 times, so you decide it would be much more efficient to script creating the EKS cluster and execute that same script 3 times to create 3 more identical environments.

<details>
<summary>Exercise 1: Create Terraform project to spin up EKS cluster</summary>
<br />

**Tasks:**

Create a Terraform project that spins up an EKS cluster with the exact same setup that you created in the previous exercise, for the same Java Gradle application:
- Create EKS cluster with 3 Nodes and 1 Fargate profile only for your java application
- Deploy Mysql with 3 replicas with volumes for data persistence using helm

Create a separate git repository for your Terraform project, separate from the Java application, so that changes to the EKS cluster can be made by a separate team independent of the application changes themselves.

**Steps to solve the tasks:**


</details>

******

<details>
<summary>Exercise 2: Configure remote state</summary>
<br />

**Tasks:**
By default, TF stores state locally. You know that this is not practical when working in a team, because each user must make sure they always have the latest state data before running Terraform. To fix that, you
- configure remote state with a remote data store for your terraform project.

You can use e.g. S3 bucket for storage.

**Steps to solve the tasks:**


</details>

******

<details>
<summary>Exercise 3: CI/CD pipeline for Terraform project</summary>
<br />

Now, the platform team that manages K8s clusters want to make changes to the cluster configurations based on the Infrastructure as Code best practices:

They collaborate and commit changes to git repository and those changes get applied to the cluster through a CI/CD pipeline.

So the AWS infrastructure and K8s cluster changes will be deployed the same way as the application changes, using a CI/CD pipeline.

So the team asks you to help them create a separate Jenkins pipeline for the Terraform project, in addition to your java-app pipeline from the previous module.

**Tasks:**
- Create a separate Jenkins pipeline for Terraform provisioning the EKS cluster

**Steps to solve the tasks:**


</details>

******