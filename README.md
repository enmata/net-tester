# Environment
- Setting default deploy region to Frankfurt for all the components
```sh
export AWS_DEFAULT_REGION=eu-central-1
```
- And Account id
```sh
export AWS_ACCOUNT_ID=519159021228
```
# Testing Core
##### Creating Docker ECR registry
- Setting up variables
```sh
export STACK_NAME_ECR=ASSESSMENT-net-tester-registry
export DOCKER_REGISTRY_NAME=net-tester-registry
```
- Validating stack file syntax
```sh
aws cloudformation validate-template --template-body file://10-Stack-ECRRegistry.yaml
```
- Creating the registry stack based the yaml template
```sh
aws cloudformation create-stack --stack-name $STACK_NAME_ECR --template-body file://10-Stack-ECRRegistry.yaml
```
##### Building and publishing Docker images to the registry
- Setting up variables
```
export DOCKER_IMAGE_NAME=net-tester-python-v1
export DOCKER_IMAGE_NAME2=net-tester-python-latest
export DOCKER_REGISTRY_FQDN=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$DOCKER_REGISTRY_NAME
```
- Building the image
```sh
cd Docker
docker build -t net-tester-python .
```
- Tagging the new image pointing to the full Docker registry name
```
docker tag $DOCKER_IMAGE_NAME $DOCKER_REGISTRY_FQDN:$DOCKER_IMAGE_NAME
```
- Logging in into the registry
```sh
aws ecr get-login-password \
    --region $AWS_DEFAULT_REGION \
| docker login \
    --username AWS \
    --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
```
- Pushing the image to the registry, and tagging it as "latest"
```sh
docker push $DOCKER_IMAGE_NAME $DOCKER_REGISTRY_FQDN:$DOCKER_IMAGE_NAME
docker tag $DOCKER_IMAGE_NAME $DOCKER_REGISTRY_FQDN:$DOCKER_IMAGE_NAME2
docker push $DOCKER_REGISTRY_FQDN:$DOCKER_IMAGE_NAME2
cd ..
```
## Storage
##### Creating Results Bucket and its non-default default policy
- Setting up variables
```sh
export STACK_NAME_BUCKETS=ASSESSMENT-ResultsBuckets
export BUCKET_NAME=results-bucket-12345
```
- Validating stack file syntax
```sh
aws cloudformation validate-template --template-body file://21-Stack-BucketResults.yaml
```
- Creating the stack from aws cli (capabilties switch is needed)
```sh
aws cloudformation create-stack --stack-name $STACK_NAME_BUCKETS --template-body file://21-Stack-BucketResults.yaml --capabilities CAPABILITY_NAMED_IAM
```
- Setting make public buket policy (deprecated)
```sh
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://22-Policy-Bucket-makePublic.json
```
## Lambda functions
- Creating test lambda functions linked to the Custom Docker images using AWS Serverless Application Model
- Using sam, a new fitted Role will be created automatically
```sh
cd LambdaCustomDocker
sam deploy -t template.yaml --no-confirm-changeset
cd ..
```
##  Step functions
- Validating stack file syntax
```sh
aws cloudformation validate-template --template-body file://40-StepStatesPipeline.json
```
- Creating the Step Functions machine from aqs cli. A role needs to be created in advance and its ARN referenced in advanced
```sh
aws stepfunctions create-state-machine --name "ASSESSMENT-StepFunctions_fromcli"  --definition file://40-StepStatesPipeline.json --type STANDARD --role-arn arn:aws:iam::519159021228:role/LambdaS3ExecutionRole
```

## Delivering File test results
##### Setting up SNS for sending eMails
- Creating topic variables
```sh
aws sns create-topic --name NewTestResultFile
aws sns subscribe --topic-arn arn:aws:sns:eu-central-1:519159021228:NewTestResultFile --protocol email --notification-endpoint example@mail.com
```
