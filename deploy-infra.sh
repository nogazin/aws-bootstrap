#!/bin/bash

STACK_NAME=awsbootstrap100
REGION=us-east-1
CLI_PROFILE=awsbootstrap

EC2_INSTANCE_TYPE=t2.micro
AWS_ACCOUNT_ID=`aws sts get-caller-identity --profile awsbootstrap --query "Account" --output text`
CODEPIPLINE_BUCKET="$STACK_NAME-$REGION-codepipeline-$AWS_ACCOUNT_ID"

# Generate a personal access token with repo and admin:repo_hook
#   permissions from https://github.com/settins/tokens
GH_ACCESS_TOKEN=$(cat ~/.github/aws-bootstrap-access-token)
GH_OWNER=$(cat ~/.github/aws-bootstrap-owner)
GH_REPO=$(cat ~/.github/aws-bootstrap-repo)
GH_BRANCH=master


#Deploy the Cloudformation template
echo -e "\n\n=========== Deploying setup.yaml ==========="
aws cloudformation deploy \
  --region $REGION \
  --profile $CLI_PROFILE \
  --stack-name $STACK_NAME \
  --template-file setup.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides CodePipelineBucket=$CODEPIPLINE_BUCKET

echo -e "\n\n=========== Deploying main.yaml ==========="
aws cloudformation deploy \
  --region $REGION \
  --profile $CLI_PROFILE \
  --stack-name $STACK_NAME \
  --template-file main.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides EC2InstanceType=$EC2_INSTANCE_TYPE \
    GitHubOwner=$GH_OWNER \
    GitHubBranch=$GH_BRANCH \
    GitHubRepo=$GH_REPO \
    GitHubPersonalAccessToken=$GH_ACCESS_TOKEN \
    CodePipelineBucket=$CODEPIPLINE_BUCKET




# If the deployment is succeeded, show the DNS name of the created instance

if [ $? -eq 0 ]; then
  aws cloudformation list-exports \
    --profile awsbootstrap \
    --query "Exports[?starts_with(Name,'LBEndpoint')].Value"
fi