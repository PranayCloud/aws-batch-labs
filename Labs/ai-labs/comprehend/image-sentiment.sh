#!/bin/bash

# --------------------------------------------------
# Usage:
# ./image-sentiment.sh <bucket-name> <image-file>
#
# Example:
# ./image-sentiment.sh test-bucket-july24-aws review.jpg
# --------------------------------------------------

BUCKET=$1
FILE=$2
REGION="us-east-1"

# Validate inputs
if [ $# -ne 2 ]; then
    echo "Usage: $0 <bucket-name> <image-file>"
    exit 1
fi

echo "========================================"
echo "Amazon Rekognition + Comprehend Demo"
echo "========================================"

echo ""
echo "Uploading image to S3..."

aws s3 cp "images/$FILE" "s3://$BUCKET/$FILE" --region $REGION

if [ $? -ne 0 ]; then
    echo "Upload Failed."
    exit 1
fi

echo "Upload Successful."
echo ""

echo "Extracting text using Amazon Rekognition..."

TEXT=$(aws rekognition detect-text \
    --image "{\"S3Object\":{\"Bucket\":\"$BUCKET\",\"Name\":\"$FILE\"}}" \
    --region $REGION \
    --query "join(' ', TextDetections[?Type=='LINE'].DetectedText)" \
    --output text)

echo ""
echo "----------------------------------------"
echo "Extracted Text:"
echo "----------------------------------------"
echo "$TEXT"

if [ -z "$TEXT" ]; then
    echo ""
    echo "No text detected in the image."
    exit 1
fi

echo ""
echo "Running Sentiment Analysis..."
echo ""

aws comprehend detect-sentiment \
    --text "$TEXT" \
    --language-code en \
    --region $REGION \
    --output table

echo ""
echo "Pipeline Completed Successfully."