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

## Requirements

### IPv6

These plans create resources with IPv6 addresses by default. In order to facilitate that, it's required to enable IPv6 for you VPC/subnets.

For instructions on how to do that, see [thes docs AWS has on the subject](https://docs.aws.amazon.com/whitepapers/latest/ipv6-on-aws/amazon-vpc-design.html).

## Usage

### Bootstrap the Prerequisite Resources

The plans use S3 as a backend and DynamoDB for state tracking. A script is included to easily generate the resources needed to support this.

```bash
./utils/generate_backend.sh
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

```text
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
