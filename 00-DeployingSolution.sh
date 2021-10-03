#!/bin/bash

# Setting default deploy region to Frankfurt for all the components
# echo 'region = eu-central-1' > ~/.aws/config
export AWS_DEFAULT_REGION=eu-central-1

# ------------------------
# 10 DOCKER
# ------------------------
# Creating Docker ECR registry
# Setting up variables
export STACK_NAME_ECR=ASSESSMENT-net-tester-registry
export Docker_registry_name=net-tester-registry
# Validating stack file syntax
aws cloudformation validate-template --template-body file://10-Stack-ECRRegistry.yaml
# Creating the registry stack based the yaml template
aws cloudformation create-stack --stack-name $STACK_NAME_ECR --template-body file://10-Stack-ECRRegistry.yaml

# Building and publishing Docker images to the registry
# Setting up variables
export aws_region=eu-central-1
export aws_account_id=XXX
export Docker_image_name=net-tester-python-v1
export Docker_image_name2=net-tester-python-latest
export Docker_registry_FQDN=$aws_account_id.dkr.ecr.$aws_region.amazonaws.com/$Docker_registry_name

# Building the image
cd Docker
docker build -t net-tester-python .
# Tagging the new image pointing to the full Docker registry name
docker tag $Docker_image_name $Docker_registry_FQDN:$Docker_image_name

# Logging in into the registry
aws ecr get-login-password \
    --region $aws_region \
| docker login \
    --username AWS \
    --password-stdin $aws_account_id.dkr.ecr.$aws_region.amazonaws.com

# Pushing the image to the registry, and tagging it as "latest"
docker push $Docker_image_name $Docker_registry_FQDN:$Docker_image_name
docker tag $Docker_image_name $Docker_registry_FQDN:$Docker_image_name2
docker push $Docker_registry_FQDN:$Docker_image_name2

cd ..

# ------------------------
# 20 Buckets
# ------------------------
# Creating Results Bucket and its non-default default policy
# Setting up variables
export STACK_NAME_BUCKETS=ASSESSMENT-ResultsBuckets
export BUCKET_NAME=results-bucket-12345
# Validating stack file syntax
aws cloudformation validate-template --template-body file://21-Stack-BucketResults.yaml
# Creating the stack from aws cli, capabilities switch is needed
aws cloudformation create-stack --stack-name $STACK_NAME_BUCKETS --template-body file://21-Stack-BucketResults.yaml --capabilities CAPABILITY_NAMED_IAM

# Setting make public policy (deprecated)
# aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://22-Policy-Bucket-makePublic.json

# ------------------------
# 30 Lambda functions
# ------------------------
# Creating test lambda functions linked to the Custom Docker images using AWS Serverless Application Model
# Using sam, a new fitted Role will be created automatically
cd LambdaCustomDocker
sam deploy -t template.yaml --no-confirm-changeset
cd ..

# ------------------------
# 40 Step functions
# ------------------------
# Validating stack file syntax
aws cloudformation validate-template --template-body file://40-StepStatesPipeline.json
# Creating the Step Functions machine from aqs cli. A role needs to be created in advance and its ARN referenced in advanced
aws stepfunctions create-state-machine --name "ASSESSMENT-StepFunctions_fromcli"  --definition file://40-StepStatesPipeline.json --type STANDARD --role-arn arn:aws:iam::519159021228:role/LambdaS3ExecutionRole

# ------------------------
# 50 Delivering File test results
# ------------------------
# Setting up SNS for sending eMails
# Creating topic variables
aws sns create-topic --name NewTestResultFile
aws sns subscribe --topic-arn arn:aws:sns:eu-central-1:519159021228:NewTestResultFile --protocol email --notification-endpoint example@mail.com
