# GitHub Actions Workflows Guide - OCI Infrastructure

## 📋 Overview

This guide explains the GitHub Actions workflows for deploying OCI infrastructure using Terraform. The workflows automate validation and deployment across all environments (dev, test, staging, prod) with modular deployment strategy.

## 🔄 Workflow Execution Order

### 1️⃣ **Terraform Plan** (First - Validation Phase)

**File:** `.github/workflows/terraform-plan.yml`  
**Trigger:** Push to branches `[dev, test, staging, main]` with changes to `environments/**` or `modules/**`  
**Purpose:** Validate Terraform syntax and preview infrastructure changes  
**Strategy:** Matrix deployment across 10 modules per environment

**Modules Matrix:**
- `networking` - VCN, subnets, gateways, security lists
- `k8s_cluster` - OKE cluster (control plane only)
- `database` - MySQL/PostgreSQL managed services
- `ocir` - Oracle Container Image Registry
- `load_balancer` - OCI Load Balancer
- `dns` - OCI DNS management
- `vault` - OCI Vault for secrets
- `iam` - Identity and Access Management
- `waf` - Web Application Firewall
- `monitoring` - OCI Monitoring and logging

**Steps executed:**
1. Checkout code
2. Setup Terraform 1.5.0
3. Set environment based on branch (dev/test/staging/prod)
4. Configure OCI CLI with API keys
5. Bootstrap resources check (dev only)
6. Setup Terraform variables from secrets
7. `terraform init` - Initialize backend and providers
8. `terraform plan` - Generate execution plan per module

### 2️⃣ **Terraform Apply** (Second - Deployment Phase)

**File:** `.github/workflows/terraform-apply.yml`  
**Trigger:** Push to branches `[dev, test, staging, main]` with changes to `environments/**` or `modules/**`  
**Purpose:** Deploy infrastructure changes to OCI  
**Strategy:** Matrix deployment across 10 modules per environment

**Steps executed:**
1. Checkout code
2. Setup Terraform 1.5.0
3. Set environment based on branch (dev/test/staging/prod)
4. Configure OCI CLI with API keys
5. Bootstrap resources check (dev only)
6. Setup Terraform variables from secrets
7. `terraform init` - Initialize backend and providers
8. `terraform apply -auto-approve` - Deploy infrastructure per module

## 🚀 Complete Deployment Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Developer modifies Terraform files                       │
│    └─> environments/oci/dev/main.tf                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Create Pull Request to main/develop                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. terraform-plan.yml triggers automatically                │
│    ├─> Runs for: dev, test, staging, prod                   │
│    ├─> terraform init                                       │
│    ├─> terraform validate                                   │
│    └─> terraform plan -out=tfplan                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Review plan output in GitHub Actions                     │
│    └─> Check resources to be created/modified/destroyed     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Merge Pull Request to main                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. terraform-apply.yml triggers automatically               │
│    ├─> Runs for: dev, test, staging, prod                   │
│    ├─> terraform init                                       │
│    └─> terraform apply -auto-approve                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. OCI Infrastructure Deployed ✅                            │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Prerequisites

### 1. OCI Tenancy Setup

**Required:**
- OCI Tenancy with proper permissions
- Compartment for resources
- Object Storage buckets for Terraform state

### 2. OCI API Key for GitHub Actions

**Create API Key:**
```bash
# Generate API key pair
mkdir -p ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem

# Display public key (upload to OCI console)
cat ~/.oci/oci_api_key_public.pem
```

**Upload Public Key to OCI:**
1. Go to OCI Console → User Settings
2. Click **API Keys**
3. Click **Add API Key**
4. Paste public key content
5. Note the fingerprint

**Get Required OCIDs:**
```bash
# Get user OCID
oci iam user list --query 'data[0].id' --raw-output

# Get tenancy OCID
oci iam tenancy get --tenancy-id $(oci iam user list --query 'data[0]."compartment-id"' --raw-output) --query 'data.id' --raw-output

# Get compartment OCID
oci iam compartment list --query 'data[0].id' --raw-output

# Get availability domain
oci iam availability-domain list --compartment-id $TENANCY_OCID --query 'data[0].name' --raw-output
```

### 3. Object Storage Backend Configuration

**Create Object Storage buckets for state storage:**
```bash
# Get namespace
export OCI_NAMESPACE=$(oci os ns get --query 'data' --raw-output)

# Create buckets for each environment
oci os bucket create --compartment-id $COMPARTMENT_ID --name terraform-state-dev
oci os bucket create --compartment-id $COMPARTMENT_ID --name terraform-state-test
oci os bucket create --compartment-id $COMPARTMENT_ID --name terraform-state-staging
oci os bucket create --compartment-id $COMPARTMENT_ID --name terraform-state-prod

# Enable versioning
oci os bucket update --bucket-name terraform-state-dev --versioning Enabled
oci os bucket update --bucket-name terraform-state-test --versioning Enabled
oci os bucket update --bucket-name terraform-state-staging --versioning Enabled
oci os bucket update --bucket-name terraform-state-prod --versioning Enabled
```

### 4. Install Required Tools

#### Terraform

**macOS:**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify installation
terraform version
```

**Linux:**
```bash
# Download Terraform
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip

# Unzip and install
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
```

#### OCI CLI

**macOS/Linux:**
```bash
# Install OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Configure OCI CLI
oci setup config

# Verify installation
oci --version
```

**Windows:**
```powershell
# Download installer from:
# https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm

# Run installer and follow prompts

# Verify installation
oci --version
```

## 📝 GitHub Repository Setup

### 1. Add Workflows to Repository

```bash
# Navigate to your repository
cd your-terraform-repo

# Create workflows directory
mkdir -p .github/workflows

# Copy OCI workflows
cp libs/pyinfrastructure-terraform-gen/references/oci/.github/workflows/* .github/workflows/

# Commit workflows
git add .github/workflows/
git commit -m "Add Terraform CI/CD workflows"
git push origin main
```

### 2. Configure GitHub Secrets

**Navigate to GitHub:**
1. Go to your repository on GitHub
2. Click **Settings**
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**

## 🔐 Required GitHub Secrets

### Core OCI Authentication Secrets

| Secret Name | Description | Example Value | Required |
|-------------|-------------|---------------|----------|
| `OCI_USER_OCID` | OCI User OCID | `ocid1.user.oc1..aaaaaaaa...` | ✅ |
| `OCI_TENANCY_OCID` | OCI Tenancy OCID | `ocid1.tenancy.oc1..aaaaaaaa...` | ✅ |
| `OCI_FINGERPRINT` | API Key Fingerprint | `aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99` | ✅ |
| `OCI_PRIVATE_KEY` | Private Key Content | `-----BEGIN RSA PRIVATE KEY-----\n...` | ✅ |
| `OCI_REGION` | OCI Region | `us-ashburn-1` | ✅ |
| `OCI_COMPARTMENT_ID` | Target Compartment OCID | `ocid1.compartment.oc1..aaaaaaaa...` | ✅ |
| `OCI_AVAILABILITY_DOMAIN` | Availability Domain | `AD-1` | ✅ |

### Database Secrets

| Secret Name | Description | Example Value | Required |
|-------------|-------------|---------------|----------|
| `DB_ADMIN_PASSWORD` | Database Admin Password | `SecureP@ssw0rd123!` | ✅ |
| `DB_USER_PASSWORD` | Database User Password | `UserP@ssw0rd456!` | ⚠️ Optional |

### Application Secrets (Optional)

| Secret Name | Description | Example Value | Required |
|-------------|-------------|---------------|----------|
| `REDIS_PASSWORD` | Redis Authentication | `RedisP@ss789!` | ⚠️ Optional |
| `JWT_SECRET` | JWT Token Secret | `jwt-secret-key-xyz` | ⚠️ Optional |
| `API_KEY` | External API Key | `api-key-12345` | ⚠️ Optional |

### SSL/TLS Certificates (Optional)

| Secret Name | Description | Example Value | Required |
|-------------|-------------|---------------|----------|
| `SSL_CERTIFICATE` | SSL Certificate Content | `-----BEGIN CERTIFICATE-----\n...` | ⚠️ Optional |
| `SSL_PRIVATE_KEY` | SSL Private Key | `-----BEGIN PRIVATE KEY-----\n...` | ⚠️ Optional |
| `CA_CERTIFICATE` | CA Certificate Bundle | `-----BEGIN CERTIFICATE-----\n...` | ⚠️ Optional |

### Monitoring & Observability (Optional)

| Secret Name | Description | Example Value | Required |
|-------------|-------------|---------------|----------|
| `GRAFANA_ADMIN_PASSWORD` | Grafana Admin Password | `GrafanaP@ss123!` | ⚠️ Optional |
| `PROMETHEUS_PASSWORD` | Prometheus Auth Password | `PrometheusP@ss456!` | ⚠️ Optional |

### External Services (Optional)

| Secret Name | Description | Example Value | Required |
|-------------|-------------|---------------|----------|
| `SLACK_WEBHOOK_URL` | Slack Notifications | `https://hooks.slack.com/...` | ⚠️ Optional |
| `DATADOG_API_KEY` | Datadog Integration | `dd-api-key-xyz` | ⚠️ Optional |
| `NEWRELIC_LICENSE_KEY` | New Relic License | `nr-license-123` | ⚠️ Optional |

### How to Add Secrets to GitHub Repository

1. Navigate to your GitHub repository
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with exact name and value

### Secret Validation Commands

```bash
# Validate OCI credentials locally
oci iam user get --user-id $OCI_USER_OCID
oci iam compartment get --compartment-id $OCI_COMPARTMENT_ID
oci iam availability-domain list --compartment-id $OCI_TENANCY_OCID

# Test API key authentication
oci iam region list
```

### 3. Verify Backend Configuration

Ensure each environment has correct backend configuration:

**File:** `environments/oci/dev/backend.tf`
```hcl
terraform {
  backend "http" {
    address = "https://objectstorage.us-ashburn-1.oraclecloud.com/n/${var.namespace}/b/terraform-state-dev/o/terraform.tfstate"
    update_method = "PUT"
  }
}
```

## 🎯 Usage Examples

### Example 1: Deploy to Dev Environment

```bash
# 1. Create feature branch
git checkout -b feature/update-dev-infrastructure

# 2. Modify Terraform configuration
vim environments/oci/dev/main.tf

# Update database module
module "database" {
  source = "../../../modules/oci/database"
  
  db_system_name = "postgres-dev"
  shape_name     = "VM.Standard.E2.1"
  # ... other parameters
}

# 3. Commit changes
git add environments/oci/dev/main.tf
git commit -m "Update OCI Database configuration for dev"

# 4. Push to dev branch
git push origin dev

# → terraform-plan.yml runs automatically for all 10 modules
# → terraform-apply.yml runs automatically for all 10 modules
# → Infrastructure deployed to OCI dev environment
```

### Example 2: Deploy to Production Environment

```bash
# 1. Update production configuration
vim environments/oci/prod/main.tf

# Change: kubernetes_version = "v1.28.2"

# 2. Commit and push to main branch
git add environments/oci/prod/main.tf
git commit -m "Update OKE to version 1.28.2 in production"
git push origin main

# → terraform-plan.yml runs automatically for all 10 modules
# → terraform-apply.yml runs automatically for all 10 modules
# → Production infrastructure updated
```

### Example 3: Branch-Based Environment Deployment

```bash
# Deploy to different environments by pushing to specific branches

# Deploy to dev
git push origin dev
# → Deploys to dev environment

# Deploy to test
git push origin test
# → Deploys to test environment

# Deploy to staging
git push origin staging
# → Deploys to staging environment

# Deploy to production
git push origin main
# → Deploys to prod environment
```

## 🔍 Monitoring and Troubleshooting

### View Workflow Runs

1. Go to **Actions** tab in GitHub repository
2. Select workflow: "Terraform Plan" or "Terraform Apply"
3. Click on specific run to view details
4. Click on environment (dev/test/staging/prod) to view logs

### Common Issues and Solutions

**Issue 1: Authentication Failed**
```
Error: Service error:NotAuthenticated
```

**Solution:**
- Verify all OCI secrets are set correctly
- Check API key fingerprint matches
- Ensure private key is complete and valid

**Issue 2: Backend Initialization Failed**
```
Error: Failed to configure backend: bucket doesn't exist
```

**Solution:**
```bash
# Create missing Object Storage bucket
oci os bucket create --compartment-id $COMPARTMENT_ID --name terraform-state-dev

# Enable versioning
oci os bucket update --bucket-name terraform-state-dev --versioning Enabled
```

**Issue 3: Bootstrap Resources Not Found**
```
Error: Compartment not found
Error: Availability domain not found
```

**Solution:**
```bash
# Verify compartment exists
oci iam compartment get --compartment-id $OCI_COMPARTMENT_ID

# List availability domains
oci iam availability-domain list --compartment-id $OCI_TENANCY_OCID

# Update GitHub secrets with correct values
```

**Issue 4: Module Deployment Failure**
```
Error: Module k8s_cluster failed to apply
```

**Solution:**
- Check module dependencies (networking must deploy first)
- Verify module-specific variables are set
- Review module logs in GitHub Actions
- For k8s_cluster: Only cluster control plane deploys, node pools excluded

### Debug Locally

```bash
# Navigate to environment
cd environments/oci/dev

# Configure OCI CLI
oci setup config

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes (if needed)
terraform apply
```

## ⚠️ Important Notes

### Security Best Practices

1. **Never commit API keys** to repository
2. **Use least privilege IAM policies** for production
3. **Enable MFA** on OCI accounts
4. **Rotate API keys** regularly (every 90 days)
5. **Enable Cloud Guard** for security monitoring
6. **Use separate compartments** for dev/staging/prod
7. **Enable Object Storage versioning** for state files
8. **Review IAM policies** regularly

### Workflow Considerations

1. **Branch-Based Deployment**: Each branch deploys to specific environment
   - `dev` branch → dev environment
   - `test` branch → test environment  
   - `staging` branch → staging environment
   - `main` branch → prod environment
2. **Modular Deployment**: 10 modules deploy in parallel per environment
3. **Auto-approve**: Apply workflow uses `-auto-approve`
4. **Bootstrap Check**: Dev environment validates required resources exist
5. **K8s Cluster**: Only control plane deploys, node pools excluded from pipeline
6. **Environment Isolation**: Each environment has separate state and secrets
7. **Matrix Strategy**: All modules run simultaneously for faster deployment

## 📚 Additional Resources

- [Terraform OCI Provider Documentation](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [OCI IAM Policies](https://docs.oracle.com/en-us/iaas/Content/Identity/Concepts/policygetstarted.htm)
- [Terraform HTTP Backend](https://www.terraform.io/docs/language/settings/backends/http.html)
- [OCI CLI Command Reference](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/)
