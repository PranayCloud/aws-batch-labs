#!/bin/bash

aws s3 cp "images/$1" "s3://test-aws-august-ai-weekend-batch/$1" --region us-east-1

aws rekognition detect-text \
    --image "S3Object={Bucket=test-aws-august-ai-weekend-batch, Name=$1}" \
    --region us-east-1 \
    --query "TextDetections[].{Text:DetectedText,Type:Type,Confidence:Confidence}" \
    --output table