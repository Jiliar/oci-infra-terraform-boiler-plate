# OCI Bootstrap Guide - Automated Infrastructure Setup

## 📋 Overview

This guide explains the automated bootstrap process for OCI infrastructure using GitHub Actions workflows that automatically create and manage Object Storage buckets for Terraform remote state.

## 🎯 Purpose

**Why Bootstrap?**
- Terraform state must be stored remotely for team collaboration
- State locking prevents concurrent modifications
- Bootstrap creates the infrastructure needed to store state
- GitHub Actions automate the entire process

**What Gets Created Automatically:**
- Single Object Storage bucket `terraform-state` (shared across environments)
- Proper security configurations (encryption, versioning, public read access)
- Automated state backup system with timestamped files

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Bootstrap Process                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 1: Deploy Bootstrap (Local State)                     │
│  └─> Creates: Object Storage Buckets                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 2: Configure Backend in Each Environment              │
│  └─> Update backend.tf with bucket names                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 3: Initialize Environments (Remote State)             │
│  └─> terraform init migrates state to Object Storage        │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Resources Created Automatically

### Object Storage Bucket (Shared State Storage)

**Bucket:**
- `terraform-state` (single bucket for all environments)

**Features:**
- ✅ **Versioning**: Enabled - keeps history of all state changes
- ✅ **Encryption**: Oracle-managed - state files encrypted at rest
- ✅ **Public Read Access**: Enabled for HTTP backend compatibility
- ✅ **Auto-Creation**: Created automatically by GitHub Actions if missing
- ✅ **State Backups**: Timestamped backup files after each deployment phase

**Purpose:**
- Store `terraform.tfstate` file remotely
- Enable team collaboration (shared state)
- Maintain state history for rollback
- Automatic backup and recovery

**Example State File Location:**
```
https://objectstorage.us-ashburn-1.oraclecloud.com/n/{namespace}/b/terraform-state-dev/o/terraform.tfstate
```

### State Locking Mechanism

**OCI uses HTTP backend with locking:**
- Lock file stored in Object Storage
- Atomic operations via HTTP API
- Lock metadata in object metadata

**How It Works:**
```
User A: terraform apply
  └─> Creates lock file in bucket
  └─> Performs infrastructure changes
  └─> Deletes lock file

User B: terraform apply (while A is running)
  └─> Attempts to create lock file
  └─> Blocked: Lock file already exists
  └─> Waits until User A completes
```

## 🚀 Automated Deployment via GitHub Actions

### Prerequisites

**Required GitHub Secrets:**
- `OCI_USER_OCID` - Your OCI user OCID
- `OCI_TENANCY_OCID` - Your OCI tenancy OCID
- `OCI_FINGERPRINT` - Your API key fingerprint
- `OCI_PRIVATE_KEY` - Your private key content
- `OCI_REGION` - Your OCI region (e.g., sa-bogota-1)
- `OCI_NAMESPACE` - Your Object Storage namespace
- `OCI_COMPARTMENT_ID` - Target compartment OCID
- `OCI_BUCKET_NAME` - Bucket name (terraform-state)
- `OCI_AUTH_TOKEN` - Auth token for HTTP backend
- `DB_ADMIN_PASSWORD` - Database admin password

**Setup GitHub Secrets:**
1. Go to your repository → Settings → Secrets and variables → Actions
2. Add each secret with the corresponding value from your OCI configuration

### Step 1: Automated Workflow Triggers

**terraform-plan.yml** (Triggered on Pull Requests):
- Automatically checks if `terraform-state` bucket exists
- Creates bucket if missing using OCI CLI
- Runs terraform plan for validation
- Only executes for dev environment initially

**terraform-apply.yml** (Triggered on PR Merge):
- Executes in 5 sequential phases:
  1. **Fundamentos** (iam, vault, ocir)
  2. **Red y Seguridad** (networking, waf)
  3. **Infraestructura Core** (database, k8s_cluster)
  4. **Servicios de Red** (load_balancer, dns)
  5. **Monitoreo** (monitoring)
- Automatically backs up tfstate after each phase
- Creates timestamped backup files in bucket

### Step 2: Manual Trigger (Development)

**Create a Pull Request:**
```bash
# Create feature branch
git checkout -b feature/initial-setup

# Make a small change to trigger workflow
echo "# Initial setup" >> README.md
git add README.md
git commit -m "Initial infrastructure setup"
git push origin feature/initial-setup
```

**Create PR targeting dev branch:**
1. Go to GitHub repository
2. Create Pull Request from `feature/initial-setup` to `dev`
3. Watch `terraform-plan.yml` workflow execute
4. Verify bucket creation in workflow logs

**Merge PR to trigger deployment:**
1. Merge the Pull Request
2. Watch `terraform-apply.yml` workflow execute
3. Monitor each phase deployment
4. Check state backup files in bucket

### Step 3: Get OCI Configuration

```bash
# Get namespace
export OCI_NAMESPACE=$(oci os ns get --query 'data' --raw-output)

# Get region
export OCI_REGION=$(oci iam region-subscription list --query 'data[0]."region-name"' --raw-output)

# Verify
echo "Namespace: $OCI_NAMESPACE"
echo "Region: $OCI_REGION"
```

### Step 4: Configure Backend for Each Environment

**Development Environment:**
```bash
cd ../dev

# Backend already configured in backend.tf
cat backend.tf
```

**Test Environment:**
```bash
cd ../test
cat backend.tf
```

**Staging Environment:**
```bash
cd ../staging
cat backend.tf
```

**Production Environment:**
```bash
cd ../prod
cat backend.tf
```

### Step 5: Initialize Each Environment

**Development:**
```bash
cd environments/oci/dev

# Initialize with remote backend
terraform init

# Terraform will prompt to migrate state
# Type 'yes' to copy local state to Object Storage
```

Output:
```
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "http" backend. No existing state was found in the newly
  configured "http" backend. Do you want to copy this state to the new "http"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes

Successfully configured the backend "http"! Terraform will automatically
use this backend unless the backend configuration changes.
```

**Verify state in Object Storage:**
```bash
oci os object list --bucket-name terraform-state-dev --query 'data[*].name'

# Expected output:
terraform.tfstate
```

**Test:**
```bash
cd ../test
terraform init
# Type 'yes' when prompted
```

**Staging:**
```bash
cd ../staging
terraform init
# Type 'yes' when prompted
```

**Production:**
```bash
cd ../prod
terraform init
# Type 'yes' when prompted
```

### Step 6: Verify State Locking

**Terminal 1:**
```bash
cd environments/oci/dev

# Start a long-running operation
terraform apply
# Don't confirm yet, leave it waiting
```

**Terminal 2:**
```bash
cd environments/oci/dev

# Try to run another operation
terraform plan
```

Expected output:
```
Error: Error acquiring the state lock

Error message: state locked
Lock Info:
  ID:        1234567890
  Path:      terraform-state-dev/terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@example.com
  Version:   1.5.0
  Created:   2024-01-15 10:30:00.000 UTC

Terraform acquires a state lock to protect the state from being written
by multiple users at the same time.
```

**Cancel Terminal 1** (Ctrl+C) and verify lock is released.

## 🔍 Verification and Testing

### Check Automated Bucket Creation

**Via GitHub Actions Logs:**
1. Go to Actions tab in your repository
2. Check `terraform-plan.yml` workflow logs
3. Look for "Bootstrap Resources Check" step
4. Verify bucket creation or existence confirmation

**Via OCI Console:**
1. Login to OCI Console
2. Navigate to Object Storage & Archive Storage
3. Check for `terraform-state` bucket
4. Verify versioning is enabled

### Check State Backup Files

**Automated Backup Files:**
- `dev_phase1_YYYYMMDD_HHMMSS.tfstate`
- `dev_phase2_YYYYMMDD_HHMMSS.tfstate`
- `dev_phase3_YYYYMMDD_HHMMSS.tfstate`
- `dev_phase4_YYYYMMDD_HHMMSS.tfstate`
- `dev_phase5_YYYYMMDD_HHMMSS.tfstate`

**Download and Inspect:**
```bash
# List all backup files
oci os object list --bucket-name terraform-state --prefix dev_phase

# Download specific backup
oci os object get --bucket-name terraform-state --name dev_phase1_20241124_143022.tfstate --file backup.json

# View backup content
cat backup.json | jq '.version'
cat backup.json | jq '.resources | length'
```

## 🔧 Troubleshooting

### Issue: Bucket Already Exists

**Error:**
```
Error: 409-Conflict, BucketAlreadyExists
```

**Solution:**
```bash
# Check if bucket exists
oci os bucket get --bucket-name terraform-state-dev

# If exists, import it
terraform import oci_objectstorage_bucket.dev terraform-state-dev
```

### Issue: State Lock Stuck

**Error:**
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>

# Or delete lock file from Object Storage
oci os object delete --bucket-name terraform-state-dev --object-name terraform.tfstate.lock --force
```

### Issue: Access Denied to Object Storage

**Error:**
```
Error: Service error:NotAuthenticated. The required information to complete authentication was not provided
```

**Solution:**
```bash
# Re-configure OCI CLI
oci setup config

# Or set environment variables
export OCI_CLI_USER=<user_ocid>
export OCI_CLI_TENANCY=<tenancy_ocid>
export OCI_CLI_REGION=<region>
export OCI_CLI_KEY_FILE=<path_to_private_key>
```

## 📊 Final Structure

```
.github/workflows/
├── terraform-plan.yml    # Auto-creates bucket, runs plans
└── terraform-apply.yml   # Sequential deployment + state backup

environments/oci/
├── dev/
│   ├── backend.tf           # Points to terraform-state bucket
│   ├── main.tf              # Infrastructure modules
│   ├── terraform.tfvars     # Tokenized variables
│   └── (state in Object Storage)
│
├── test/
│   ├── backend.tf           # Points to terraform-state bucket
│   ├── main.tf
│   └── (state in Object Storage)
│
├── staging/
│   ├── backend.tf
│   ├── main.tf
│   └── (state in Object Storage)
│
└── prod/
    ├── backend.tf
    ├── main.tf
    └── (state in Object Storage)

Object Storage Bucket: terraform-state
├── dev.tfstate                    # Main state file
├── dev_phase1_20241124_143022.tfstate  # Backup files
├── dev_phase2_20241124_143045.tfstate
├── dev_phase3_20241124_143102.tfstate
├── dev_phase4_20241124_143125.tfstate
└── dev_phase5_20241124_143150.tfstate
```

## ⚠️ Important Notes

1. **Fully automated bootstrap** - No manual terraform commands needed
2. **Single shared bucket** - All environments use `terraform-state` bucket
3. **GitHub Actions handle everything** - Bucket creation, state management, backups
4. **Sequential deployment phases** - Prevents resource dependency issues
5. **Automatic state backups** - Timestamped files after each phase
6. **Public read access** - Required for HTTP backend compatibility
7. **Environment-specific state files** - `dev.tfstate`, `test.tfstate`, etc.
8. **Secrets management** - All credentials stored in GitHub Secrets

## 🔐 Security Best Practices

1. **Restrict Object Storage access** - Use IAM policies
2. **Enable versioning** - Maintain state history
3. **Audit access logs** - Enable Object Storage logging
4. **Use compartments** - Isolate resources
5. **Rotate API keys** - Change keys regularly
6. **Use separate tenancies** - Isolate prod from non-prod
7. **Review IAM policies** - Ensure least privilege

## 📚 Additional Resources

- [Terraform HTTP Backend Documentation](https://www.terraform.io/docs/language/settings/backends/http.html)
- [OCI Object Storage Versioning](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/usingversioning.htm)
- [OCI IAM Policies](https://docs.oracle.com/en-us/iaas/Content/Identity/Concepts/policygetstarted.htm)
- [Terraform State Management](https://www.terraform.io/docs/language/state/index.html)
