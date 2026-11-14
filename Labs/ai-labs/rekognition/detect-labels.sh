#!/bin/bash

aws s3 cp "images/$1" "s3://test-aws-august-ai-weekend-batch/$1" --region us-east-1

aws rekognition detect-labels \
    --image "S3Object={Bucket=test-aws-august-ai-weekend-batch, Name=$1}" \
    --region us-east-1 \
    --max-labels 10 \
    --min-confidence 90 \
    --query "Labels[].{Label:Name,Confidence:Confidence}" \
    --output table
