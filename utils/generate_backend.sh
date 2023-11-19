#!/bin/bash

#
# Helper script for generating the resources needed to support an S3 backend for Terraform
# Thanks ChatGPT :)
#

PROJ_NAME="ip2cr"
AWS_ACCT_NUM=""

# Set the bucket and table names
S3_BUCKET_NAME="tf-${PROJ_NAME}-${AWS_ACCT_NUM}"
DYNAMODB_TABLE_NAME="tf-${PROJ_NAME}"

# Create S3 bucket
echo "Creating S3 bucket..."
aws s3api create-bucket --bucket $S3_BUCKET_NAME --region $AWS_REGION --profile $AWS_PROFILE

# Create DynamoDB table
echo "Creating DynamoDB table..."
aws dynamodb create-table \
  --table-name $DYNAMODB_TABLE_NAME \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region $AWS_REGION \
  --profile $AWS_PROFILE

# Wait for DynamoDB table to be created
echo "Waiting for DynamoDB table to initialize..."
aws dynamodb wait table-exists --table-name $DYNAMODB_TABLE_NAME --region $AWS_REGION --profile $AWS_PROFILE

echo "S3 bucket and DynamoDB table created successfully!"
