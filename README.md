# Kubernetes Infrastructure Management (k8s-infra)

This repository provides Terraform-based infrastructure-as-code (IaC) templates to manage Kubernetes clusters and associated resources in a cloud environment. It includes both the Terraform configurations and a GitHub Actions workflow to streamline the deployment process.

---

## Table of Contents
1. [Overview](#overview)
2. [Repository Structure](#repository-structure)
3. [Setup Instructions](#setup-instructions)
4. [Terraform Modules](#terraform-modules)
5. [Configuration Files](#configuration-files)
6. [Workflows](#workflows)
7. [Usage](#usage)
8. [Troubleshooting](#troubleshooting)

---

## Overview

The `k8s-infra` project simplifies the management of Kubernetes infrastructure using Terraform (OpenTofu). It provides:
- Pre-configured Terraform files for creating and managing Kubernetes clusters.
- Modular support for environment-specific configurations.
- Automated deployment pipelines via GitHub Actions.

---

## Repository Structure

```
├── main.tf              # Primary Terraform configuration file.
├── providers.tf         # Defines the required Terraform providers.
├── variables.tf         # Input variables for the Terraform module.
├── outputs.tf           # Output variables for the Terraform module.
├── backend.tf           # Remote backend configuration for state storage.
├── bootstrap/           # Bootstrap resources for Terraform initialization.
│   ├── main.tf          # Bootstrap-specific Terraform configuration.
│   └── variables.tf     # Variables for the bootstrap phase.
├── config/              # Environment-specific variable files.
│   └── sandbox.tfvars   # Variables for the 'sandbox' environment.
├── .github/workflows/   # GitHub Actions workflows for CI/CD.
└── README.md            # Documentation for the repository.
```

---

## Setup Instructions

1. **Prerequisites**:
   - Install [Terraform](https://www.terraform.io/downloads) or [OpenTofu](https://opentofu.com/).
   - Configure access credentials for your cloud provider.

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Plan Infrastructure Changes**:
   ```bash
   terraform plan -var-file=config/sandbox.tfvars
   ```

4. **Apply Infrastructure Changes**:
   ```bash
   terraform apply -var-file=config/sandbox.tfvars
   ```

---

## Terraform Modules

### 1. VPC Module

The VPC module uses the [Terraform AWS VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) to create a VPC with the following:
- **Private Subnets**: For internal resources like Kubernetes nodes.
- **Public Subnets**: For external-facing resources like load balancers.
- **NAT Gateways**: Configurable for internet access from private subnets.

#### Example Configuration:
```hcl
module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  name                 = var.vpc_name
  cidr                 = var.vpc_cidr
  azs                  = var.vpc_azs
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  tags                 = var.tags
}
```

### 2. EKS Module

The EKS module uses the [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) to deploy and manage an Elastic Kubernetes Service (EKS) cluster.

#### Example Configuration:
```hcl
module "eks" {
  source                              = "terraform-aws-modules/eks/aws"
  version                             = "~> 20.0"
  cluster_name                        = var.cluster_name
  cluster_version                     = var.cluster_version
  cluster_endpoint_public_access      = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_addons                      = var.cluster_addons
  vpc_id                              = module.vpc.vpc_id
  subnet_ids                          = module.vpc.private_subnets
  eks_managed_node_groups             = var.eks_managed_node_groups
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  access_entries                      = var.access_entries
  tags                                = var.tags
}
```

---

## Configuration Files

### Sandbox Environment (`sandbox.tfvars`)

This file customizes Terraform for the "sandbox" environment.

#### Example Configuration:
```hcl
tags = {
  Project     = "k8s-task"
  Environment = "SANDBOX"
  ManagedBy   = "alytaha46@gmail.com"
  Terraform   = "true"
}

# VPC
vpc_name        = "k8s-task-vpc"
vpc_cidr        = "10.0.0.0/16"
vpc_azs         = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

# EKS
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
    principal_arn = "arn:aws:iam::651980439276:user/alytaha46"
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
```

---

## Workflows

### Task Infrastructure Workflow

The GitHub Actions workflow, **Task Infrastructure**, provides a flexible way to manage Terraform infrastructure.

#### Features:
- **Manual Trigger**: Triggered via the GitHub Actions interface (`workflow_dispatch`).
- **Actions Supported**:
  - `plan`: Generate an execution plan for the Terraform infrastructure.
  - `apply`: Apply changes to the infrastructure.
  - `destroy`: Destroy existing infrastructure resources.
- **Customizability**:
  - Specify a target module for more granular operations.
  - Optionally provide a backend configuration file.

#### Steps:
1. **Checkout Code**: Fetches the repository code.
2. **AWS Credentials Setup**: Configures AWS using secrets stored in GitHub.
3. **Terraform Initialization**:
   - Reconfigures Terraform with or without a backend configuration file.
4. **Execute Action**:
   - Runs the appropriate Terraform command (`plan`, `apply`, `destroy`), optionally targeting a specific module.

#### Example Workflow Dispatch Configuration:
When triggering the workflow, you can provide inputs like:
```yaml
action: plan
module: module-name
backend_config_file: config/backend.tf
```

---

## Usage

1. **Customize Variables**:
   - Modify files in `config/` to define environment-specific settings.
   - Example: Adjust `sandbox.tfvars` for the sandbox environment.

2. **Run Locally**:
   - Use Terraform commands (`plan`, `apply`, `destroy`) to manage infrastructure manually.

3. **Automate via GitHub Actions**:
   - Navigate to the **Actions** tab in the repository.
   - Trigger the **Task Infrastructure** workflow, providing inputs for `action`, `module`, and `backend_config_file` as needed.

---

## Troubleshooting

- **Common Errors**:
  - Ensure proper provider credentials are configured.
  - Run `terraform validate` to check for syntax issues.
- **Workflow Issues**:
  - Verify that required GitHub secrets (e.g., `AWS_ACCESS_KEY_ID`) are correctly configured.
  - Check the Actions logs for detailed error messages.

---
