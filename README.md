# tf-ip2cr

Terraform plans for generating ephemeral test resources for testing ip2cr.

## Summary

Currently, this set of terraform plans:

1. Generates an EC2 instance
1. Creates a NLB
1. Creates an ALB
1. Creates a CloudFront distribution
1. Attaches the CloudFront distribution to the ALB
1. Attaches the ALB to the EC2 instance
1. Separately, attaches the NLB to the EC2 instance

This should provide several vectors for testing IP2CR.

## Usage

### Bootstrap the Prerequisite Resources

The plans use S3 as a backend and DynamoDB for state tracking. A standalone Terraform plan is included to generate the prerequisite infrastructure to support this:

```bash
cd ./utils/generate_backend/
terraform init && terraform apply
```

After Terraform completes its run, it should include the S3 bucket name and DynamoDB table name in the output; keep this handy as we will need it for the next step.

Example:

```bash
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

tf-s3-bucket-metadata = [
  "tf-ip2cr-20240215195635031500000001",
  "tf-ip2cr",
]
```

#### Generate Backend Vars

Generate a `backend.tfvars` file in the project root and fill in the variables as appropriate.

```hcl
bucket = "<TF_S3_BUCKET_NAME>"
key    = "terraform.tfstate"
region = "<DEPLOY_REGION>"

dynamodb_table = "<TF_DYNAMODB_TABLE_NAME>"

```

Example:

```hcl
bucket = "tf-ip2cr-aws"
key    = "terraform.tfstate"
region = "us-east-1"

dynamodb_table = "tf-ip2cr"

```

### Set TF Vars

Generate a `terraform.tfvars` file and fill in the variables as approriate.

```hcl
ami_id = "<EC2_AMI>"  # any AMI of your choice can be used
key_pair_name = "<EC2_SSH_KEY_PAIR_NAME>"
subnets = [<SUBNETS_FOR_LBS>]
vpc = "<VPC>"
```

Example:

```hcl
ami_id = "ami-053b0d53c279acc90"  # Ubuntu Server 22.04 LTS
key_pair_name = "default"
subnets = ["subnet-123456789", "subnet-987654321"]
vpc = "vpc-12345abcde"
```

### Plan and Apply Plans

A Make file has been included to make running these plans easier. There is no need to initialize the environment, or any other prerequesite work, prior to running these commands.

#### Plan

```bash
make plan
```

#### Apply

```bash
make apply
```
