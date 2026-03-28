# mex-open-data-aws-s3

Terraform infrastructure for the Mexican government open data lake. Provisions an S3 data lake, IAM roles, Glue crawler, Athena workgroup, and a monitoring stack (CloudWatch, SNS, CloudTrail) in a single `terraform apply`.

---

## Architecture

```
datos.gob.mx
      │
      │  (Airflow pipeline — mex-open-data-pipeline)
      ▼
┌─────────────────────────────────────────────────────────┐
│                   S3 Data Lake                          │
│                                                         │
│  raw/{category}/{dataset}/                              │
│    _metadata.json        ← DatasetDetail (JSON)         │
│    resources/{id}.csv    ← original CSV                 │
│    resources/{id}.xlsx   ← original Excel               │
│    resources/{id}.json   ← Excel → JSON conversion      │
│                                                         │
│  curated/{category}/{dataset}/{resource_id}/            │
│    data.parquet          ← CSV converted to Parquet     │
│                                                         │
│  logs/          ← S3 server access logs                 │
│  cloudtrail/    ← CloudTrail audit logs                 │
│  athena-results/← Athena query output (expires 30 d)   │
└─────────────────────────────────────────────────────────┘
      │                          │
      │ Glue crawler             │ Athena
      ▼ (Mon-Fri noon UTC)       ▼ (ad-hoc queries)
┌──────────────┐         ┌──────────────────┐
│ Glue Catalog │         │ Athena Workgroup  │
│ mex_open_data│         │ mex-open-data     │
└──────────────┘         │ (engine v3, 1 GB) │
                         └──────────────────┘

Monitoring
  EventBridge ──► SNS ──► email   (Glue crawler failures)
  CloudWatch  ──► SNS ──► email   (S3 4xx/5xx errors)
  CloudTrail  ──────────────────► cloudtrail/ in S3
```

---

## Modules

| Module | Resources | Purpose |
|--------|-----------|---------|
| `s3` | `aws_s3_bucket` + versioning, SSE, lifecycle, logging | Data lake bucket |
| `iam` | Pipeline role + instance profile, Glue service role | Least-privilege access |
| `glue` | Glue DB + crawler | Catalog `curated/` Parquet files |
| `athena` | Workgroup (engine v3, 1 GB cost guard) | Ad-hoc SQL queries |
| `monitoring` | SNS, EventBridge, CloudWatch alarms, CloudTrail | Alerting and audit |

---

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured (`aws configure` or environment variables)
- An AWS account with permissions to create S3, IAM, Glue, Athena, CloudWatch, SNS, CloudTrail resources

---

## First-time setup — remote state

Terraform state is stored remotely in S3 with DynamoDB locking. Run `bootstrap/` **once** to create those resources before initialising the main stack.

```bash
cd bootstrap
terraform init
terraform apply
# Note the outputs: state_bucket_name and lock_table_name
```

Then in the root directory:

```bash
cp backend.hcl.example backend.hcl
# Edit backend.hcl — fill in bucket, region, dynamodb_table from bootstrap output
```

---

## Deploy

```bash
# 1. Initialise with remote backend
terraform init -backend-config=backend.hcl

# 2. Copy and fill in variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set alert_email at minimum

# 3. Preview changes
terraform plan

# 4. Apply
terraform apply
```

After apply, `terraform output` prints everything the Airflow pipeline needs:

```
bucket_name                    = "mex-open-data-lake-123456789012"
glue_crawler_name              = "mex-open-data-curated-crawler"
pipeline_instance_profile_name = "mex-open-data-pipeline-profile"
alerts_sns_topic_arn           = "arn:aws:sns:..."
cloudtrail_name                = "mex-open-data-trail"
```

**Important:** After the first apply, AWS sends a confirmation email to `alert_email`. Click the link to activate SNS notifications.

---

## Variables

| Name | Default | Description |
|------|---------|-------------|
| `aws_region` | `mx-central-1` | AWS region |
| `environment` | `prod` | Environment tag |
| `bucket_name_prefix` | `mex-open-data-lake` | S3 bucket prefix; account ID appended |
| `glue_schedule` | `cron(0 12 ? * MON-FRI *)` | Glue crawler cron (AWS format) |
| `alert_email` | — | Email for Glue failure and S3 error alerts |

> **Note on region:** `mx-central-1` (AWS Mexico Central) is a recently launched region. Verify Glue and Athena availability before applying:
> ```bash
> aws glue list-crawlers --region mx-central-1
> aws athena list-work-groups --region mx-central-1
> ```
> If unavailable, change `aws_region` to `us-east-1`.

---

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | S3 data lake bucket name |
| `bucket_arn` | S3 data lake bucket ARN |
| `pipeline_role_arn` | IAM role ARN for the EC2 instance |
| `pipeline_instance_profile_name` | Instance profile to attach to EC2 |
| `glue_database_name` | Glue catalog database (`mex_open_data`) |
| `glue_crawler_name` | Crawler name — set as Airflow Variable `GLUE_CRAWLER_NAME` |
| `athena_workgroup_name` | Athena workgroup name |
| `alerts_sns_topic_arn` | SNS topic ARN for pipeline alerts |
| `cloudtrail_name` | CloudTrail trail name |

---

## IAM permissions summary

**Pipeline role** (attached to EC2 running Airflow):

| Prefix | Permissions |
|--------|-------------|
| `raw/*` | `GetObject`, `PutObject`, `ListBucket`, `GetBucketLocation` |
| `curated/*` | `GetObject`, `PutObject` — no `DeleteObject` |
| `*` (multipart) | `CreateMultipartUpload`, `UploadPart`, `CompleteMultipartUpload`, `AbortMultipartUpload`, `ListMultipartUploadParts` |
| Glue | `StartCrawler`, `GetCrawler`, `GetCrawlerMetrics` on `arn:aws:glue:*:*:crawler/mex-open-data-*` |
| CloudWatch | `CloudWatchAgentServerPolicy` (managed) |

**Glue service role**: `AWSGlueServiceRole` (managed) + `GetObject`/`ListBucket` on `curated/*`.

---

## Lifecycle policy

| Prefix | Rule |
|--------|------|
| `raw/` | Transition to Glacier after 90 days; expire after 365 days |
| `curated/` | Retained indefinitely (always queryable via Athena) |
| `athena-results/` | Expire after 30 days |

---

## Troubleshooting

**`terraform init` fails with "bucket does not exist"**
Run `bootstrap/` first to create the state bucket, then fill in `backend.hcl`.

**Glue crawler fails immediately**
Check that the IAM Glue role has `AWSGlueServiceRole` attached and that `curated/` contains at least one Parquet file.

**No alert emails received**
Confirm the SNS subscription — AWS sends a confirmation email on first `terraform apply`. Check the spam folder.

**Athena queries fail with "output location not set"**
The workgroup enforces the output location. Query via the `mex-open-data` workgroup, not the primary workgroup.

**`mx-central-1` service not available**
Set `aws_region = "us-east-1"` in `terraform.tfvars` and re-apply.
