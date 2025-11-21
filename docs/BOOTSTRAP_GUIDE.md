# OCI Bootstrap Guide - Object Storage Backend Setup

## 📋 Overview

This guide explains how to bootstrap OCI infrastructure by creating Object Storage buckets for Terraform remote state management.

## 🎯 Purpose

**Why Bootstrap?**
- Terraform state must be stored remotely for team collaboration
- State locking prevents concurrent modifications
- Bootstrap creates the infrastructure needed to store state

**What Gets Created:**
- 4 Object Storage buckets (one per environment)
- Proper security configurations (encryption, versioning, access control)

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

## 📦 Resources Created

### Object Storage Buckets (State Storage)

**Buckets:**
- `terraform-state-dev`
- `terraform-state-test`
- `terraform-state-staging`
- `terraform-state-prod`

**Features:**
- ✅ **Versioning**: Enabled - keeps history of all state changes
- ✅ **Encryption**: Oracle-managed - state files encrypted at rest
- ✅ **Access Control**: IAM policies restrict access
- ✅ **Lifecycle Rules**: Old versions retained for 90 days
- ✅ **Pre-Authenticated Requests**: Disabled for security

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

## 🚀 Step-by-Step Deployment

### Prerequisites

**Required:**
- OCI CLI configured
- Terraform 1.5.0+ installed
- OCI tenancy with proper permissions
- Compartment OCID

**Verify Setup:**
```bash
# Check OCI CLI configuration
oci iam user get --user-id $(oci iam user list --query 'data[0].id' --raw-output)

# Check Terraform version
terraform version

# Expected: Terraform v1.5.0 or higher

# Get compartment OCID
export COMPARTMENT_ID=$(oci iam compartment list --query 'data[0].id' --raw-output)
echo $COMPARTMENT_ID
```

### Step 1: Configure OCI CLI

```bash
# Run OCI setup if not configured
oci setup config

# Test configuration
oci os ns get

# Expected output: your namespace
```

### Step 2: Deploy Bootstrap Infrastructure

**Navigate to bootstrap directory:**
```bash
cd environments/oci/bootstrap
```

**Review configuration:**
```bash
cat main.tf
```

**Initialize Terraform:**
```bash
terraform init
```

Output:
```
Initializing the backend...
Initializing provider plugins...
- Finding oracle/oci versions matching "~> 5.0"...
- Installing oracle/oci v5.10.0...

Terraform has been successfully initialized!
```

**Plan deployment:**
```bash
terraform plan
```

Review output:
```
Plan: 4 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + dev_bucket_name     = "terraform-state-dev"
  + prod_bucket_name    = "terraform-state-prod"
  + staging_bucket_name = "terraform-state-staging"
  + test_bucket_name    = "terraform-state-test"
```

**Apply configuration:**
```bash
terraform apply
```

Type `yes` when prompted.

**Verify resources created:**
```bash
# List Object Storage buckets
oci os bucket list --compartment-id $COMPARTMENT_ID --query 'data[*].name' | grep terraform-state

# Expected output:
terraform-state-dev
terraform-state-test
terraform-state-staging
terraform-state-prod
```

**Check bucket configuration:**
```bash
# Check versioning
oci os bucket get --bucket-name terraform-state-dev --query 'data.versioning'

# Expected output: "Enabled"

# Check encryption
oci os bucket get --bucket-name terraform-state-dev --query 'data."kms-key-id"'
```

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

### Check Object Storage State File

```bash
# Download state file
oci os object get --bucket-name terraform-state-dev --name terraform.tfstate --file state-backup.json

# View state
cat state-backup.json | jq '.version'
cat state-backup.json | jq '.resources | length'

# List object versions
oci os object list-object-versions --bucket-name terraform-state-dev --prefix terraform.tfstate
```

### Test State Rollback

```bash
# List versions
oci os object list-object-versions --bucket-name terraform-state-dev --prefix terraform.tfstate

# Restore previous version
oci os object restore --bucket-name terraform-state-dev --object-name terraform.tfstate --version-id <VERSION_ID>
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
environments/oci/
├── bootstrap/
│   ├── main.tf              # Creates Object Storage buckets
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfstate    # Local state (bootstrap only)
│
├── dev/
│   ├── backend.tf           # Points to Object Storage bucket
│   ├── main.tf
│   └── (state in Object Storage)
│
├── test/
│   ├── backend.tf
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
```

## ⚠️ Important Notes

1. **Bootstrap uses local state** - Only bootstrap environment stores state locally
2. **All other environments use remote state** - Dev, test, staging, prod use Object Storage
3. **Never delete bootstrap state** - Keep `bootstrap/terraform.tfstate` safe
4. **Bucket names must be unique** - Within your tenancy
5. **State locking via HTTP backend** - Uses Object Storage API
6. **Versioning is enabled** - Can rollback to previous states
7. **Encryption is automatic** - Oracle-managed encryption by default

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
