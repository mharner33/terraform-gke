# GCP GKE Terraform Infrastructure

Terraform configuration for deploying a GKE cluster on GCP using service account impersonation.

## Prerequisites

- Terraform ~> 1.13.3
- `gcloud` CLI installed and configured
- Permissions to impersonate a service account with GKE admin rights

## Service Account Impersonation Setup

### Option 1: Using gcloud config (Recommended)

```bash
# Set the service account to impersonate
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="sa-name@project-id.iam.gserviceaccount.com"

# Verify impersonation works
gcloud config set auth/impersonate_service_account $GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
```

### Option 2: Using environment variable

```bash
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="sa-name@project-id.iam.gserviceaccount.com"
```

## Configuration

### 1. Configure Backend

Edit `backend.tf` and replace `{bucket-name}` with your actual GCS bucket:

```hcl
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "tfstate"
  }
}
```

### 2. Set Variables

Copy and modify `terraform.tfvars` with your values:

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
zone       = "us-central1-c"

network = {
  name                = "your-vpc-name"
  subnetwork_name     = "your-subnet-name"
  nodes_cidr_range    = "10.128.0.0/20"      # CIDR for GKE nodes
  pods_cidr_range     = "10.4.0.0/14"        # CIDR for pods (secondary range)
  services_cidr_range = "10.8.0.0/20"        # CIDR for services (secondary range)
}

gke = {
  name     = "your-cluster-name"
  regional = false                            # true = regional, false = zonal
  zones    = ["us-central1-c"]               # Zones for node distribution
}

node_pool = {
  name               = "your-node-pool-name"
  machine_type       = "e2-standard-2"       # VM machine type
  spot               = false                  # true = spot instances, false = regular
  initial_node_count = 3                      # Initial nodes per zone
  max_count          = 4                      # Max nodes for autoscaling
  disk_size_gb       = 20                     # Boot disk size
}
```

### Variable Details

| Variable | Required | Description |
|----------|----------|-------------|
| `project_id` | Yes | GCP project ID |
| `region` | No | Default region (default: us-central1) |
| `zone` | No | Default zone (default: us-central1-c) |
| `network.name` | Yes | VPC network name |
| `network.subnetwork_name` | Yes | Subnet name |
| `network.nodes_cidr_range` | No | Primary CIDR for nodes (default: 10.128.0.0/20) |
| `network.pods_cidr_range` | No | Secondary CIDR for pods (default: 10.4.0.0/14) |
| `network.services_cidr_range` | No | Secondary CIDR for services (default: 10.8.0.0/20) |
| `gke.name` | Yes | GKE cluster name |
| `gke.regional` | No | Regional vs zonal cluster (default: false) |
| `gke.zones` | Yes | List of zones for node distribution |
| `node_pool.name` | Yes | Node pool name |
| `node_pool.machine_type` | No | VM machine type (default: e2-standard-2) |
| `node_pool.spot` | No | Use spot instances (default: true) |
| `node_pool.initial_node_count` | No | Initial nodes per zone (default: 3) |
| `node_pool.max_count` | No | Max nodes for autoscaling (default: 4) |
| `node_pool.disk_size_gb` | No | Boot disk size in GB (default: 10) |

## Deployment

### Initialize Terraform

```bash
# Initialize providers and backend
terraform init
```

If the backend bucket doesn't exist, create it first:

```bash
gsutil mb -p your-project-id -l us-central1 gs://your-terraform-state-bucket
gsutil versioning set on gs://your-terraform-state-bucket
```

### Plan Changes

```bash
# Review what will be created
terraform plan
```

### Apply Configuration

```bash
# Deploy infrastructure
terraform apply
```

Or auto-approve:

```bash
terraform apply -auto-approve
```

### Get Cluster Credentials

After deployment, configure kubectl:

```bash
gcloud container clusters get-credentials $(terraform output -raw cluster_name) \
  --zone=$(terraform output -raw cluster_zone) \
  --project=$(terraform output -raw project_id)
```

Or if using impersonation:

```bash
gcloud container clusters get-credentials $(terraform output -raw cluster_name) \
  --zone=$(terraform output -raw cluster_zone) \
  --project=$(terraform output -raw project_id) \
  --impersonate-service-account=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
```

## Outputs

Available outputs after deployment:

```bash
terraform output                    # Show all outputs
terraform output cluster_name       # Get cluster name
terraform output cluster_endpoint   # Get cluster endpoint
terraform output project_id         # Get project ID
```

## Destroy Infrastructure

```bash
# Destroy all resources
terraform destroy
```

## Troubleshooting

### Permission Issues

Ensure your service account has these roles:
- `roles/compute.admin`
- `roles/container.admin`
- `roles/iam.serviceAccountUser`

Grant impersonation rights:

```bash
gcloud iam service-accounts add-iam-policy-binding sa-name@project-id.iam.gserviceaccount.com \
  --member="user:your-email@example.com" \
  --role="roles/iam.serviceAccountTokenCreator"
```

### State Lock Issues

If state is locked:

```bash
terraform force-unlock LOCK_ID
```

### Verify Impersonation

```bash
gcloud auth list
# Should show your service account with (impersonated) suffix
```

