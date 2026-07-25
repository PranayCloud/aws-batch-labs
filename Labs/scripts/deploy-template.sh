#!/bin/bash

STACK_NAME=$1
TEMPLATE_FILE=$2

echo "Validating CloudFormation template..."
aws cloudformation validate-template --template-body file://$TEMPLATE_FILE

aws cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --template-file "$TEMPLATE_FILE" \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        VpcCidr="$3" \
        vpcname="$4"