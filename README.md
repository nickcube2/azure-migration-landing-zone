# Azure Migration Landing Zone

Production-grade Azure landing zone built with Terraform, demonstrating
enterprise cloud migration infrastructure as deployed on client engagements.

## Architecture
### Modules

| Module | Resources | Purpose |
|--------|-----------|---------|
| `networking` | Hub VNet, Spoke VNet, NSGs, Peering | Network isolation, hub-spoke topology |
| `identity` | Key Vault, Managed Identity, RBAC | Zero-credential architecture |
| `compute` | AKS cluster, Log Analytics | Container workload platform |
| `data` | ADLS Gen2, Private Endpoints | Databricks-ready data lake |
| `migration` | DMS, Recovery Vault, Staging Storage | Migration execution tooling |

## Security Design

- **Zero credentials** — all authentication via managed identity and RBAC
- **Private endpoints** — Key Vault, ADLS Gen2 accessible only from VNet
- **NSG allow-list** — explicit deny-all rules on AKS and data subnets
- **Key Vault RBAC** — `Key Vault Secrets User` for app, `Key Vault Administrator` for Terraform
- **AKS workload identity** — pods authenticate to Azure services via OIDC federation

## CI/CD Pipeline
## Migration Tooling

**Azure Database Migration Service (DMS)**
- SKU: `Premium_4vCores` — supports CDC (continuous replication)
- Deployed in `snet-migration` subnet
- Supports: SQL Server, MySQL, PostgreSQL, Oracle → Azure SQL

**Azure Site Recovery (Recovery Services Vault)**
- Replicates on-prem VMs to Azure continuously
- On cutover: VM launches in Azure with replicated state
- Soft delete enabled — 14-day recovery window

**Data Lake — Medallion Architecture**
- `bronze` — raw data exactly as ingested
- `silver` — cleaned, validated, deduplicated
- `gold` — aggregated, business-ready

> **Note:** Bronze/silver/gold containers provisioned via Azure CLI
> due to free tier public network restrictions on ADLS Gen2.
> In production, these are created via Terraform with private endpoint
> access from a self-hosted runner inside the VNet.

## AWS → Azure Reference

| AWS | Azure |
|-----|-------|
| VPC | VNet |
| Security Groups | NSGs |
| IAM Instance Profile | Managed Identity |
| EKS | AKS |
| S3 | ADLS Gen2 / Blob Storage |
| Secrets Manager | Key Vault |
| CloudWatch | Azure Monitor / Log Analytics |
| DMS | Azure Database Migration Service |
| MGN | Azure Site Recovery |
| Transit Gateway | Azure Virtual WAN |

## Prerequisites

```bash
az --version          # Azure CLI 2.85+
terraform --version   # Terraform 1.14+
kubectl version       # kubectl for AKS verification
```

## Usage

```bash
# Authenticate
az login

# Clone and initialise
git clone https://github.com/nickcube2/azure-migration-landing-zone
cd azure-migration-landing-zone
terraform init

# Configure (copy and edit)
cp terraform.tfvars.example terraform.tfvars

# Deploy
terraform plan
terraform apply
```

## Connect to AKS

```bash
az aks get-credentials \
  --resource-group rg-kpmg-workload-dev \
  --name aks-kpmg-dev

kubectl get nodes
kubectl get pods --all-namespaces
```

## Verify Data Lake

```bash
az storage account show \
  --name <storage-account-name> \
  --resource-group rg-kpmg-data-dev \
  --query "{endpoint:primaryEndpoints.dfs, hns:isHnsEnabled}"
```

## Cost Management

All resources tagged for billing allocation:
- `Environment`: dev
- `Project`: kpmg-migration
- `ManagedBy`: terraform
- `Owner`: nicholas-awuni
- `CostCenter`: lighthouse-demo

## Author

Nicholas Awuni — Senior DevOps/Cloud Engineer
[linkedin.com/in/nicholas-awuni-6018041b1](https://linkedin.com/in/nicholas-awuni-6018041b1)
