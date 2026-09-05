#!/bin/bash

# Usage:
# ./image-rekognition.sh <bucket-name> <file-name> <operation>

# Example:
# ./image-rekognition.sh test-bucket-july24-aws dog.jpg labels
# ./image-rekognition.sh test-bucket-july24-aws invoice.jpg text
# ./image-rekognition.sh test-bucket-july24-aws person.jpg faces

BUCKET=$1
FILE=$2
OPERATION=$3
REGION="us-east-1"

# Validate inputs
if [ $# -ne 3 ]; then
    echo "Usage: $0 <bucket-name> <file-name> <labels|text|faces>"
    exit 1
fi

echo "--------------------------------------------"
echo "Bucket    : $BUCKET"
echo "File      : $FILE"
echo "Operation : $OPERATION"
echo "--------------------------------------------"

# Upload file to S3
aws s3 cp "images/$FILE" "s3://$BUCKET/$FILE" --region $REGION

if [ $? -ne 0 ]; then
    echo "Upload failed."
    exit 1
fi

echo ""
echo "Image uploaded successfully."
echo ""

case "$OPERATION" in

labels)
    echo "Running Label Detection..."
    aws rekognition detect-labels \
        --image "{\"S3Object\":{\"Bucket\":\"$BUCKET\",\"Name\":\"$FILE\"}}" \
        --max-labels 10 \
        --min-confidence 90 \
        --region $REGION \
        --query "Labels[].{Label:Name,Confidence:Confidence}" \
        --output table
    ;;

text)
    echo "Running Text Detection..."
    aws rekognition detect-text \
        --image "{\"S3Object\":{\"Bucket\":\"$BUCKET\",\"Name\":\"$FILE\"}}" \
        --region $REGION \
        --query "TextDetections[].{Text:DetectedText,Type:Type,Confidence:Confidence}" \
        --output table
    ;;

faces)
    echo "Running Face Detection..."
    aws rekognition detect-faces \
        --image "{\"S3Object\":{\"Bucket\":\"$BUCKET\",\"Name\":\"$FILE\"}}" \
        --attributes ALL \
        --region $REGION \
        --query "FaceDetails[].{AgeLow:AgeRange.Low,AgeHigh:AgeRange.High,Smile:Smile.Value,Gender:Gender.Value,Confidence:Confidence}" \
        --output table
    ;;

*)
    echo "Invalid operation."
    echo ""
    echo "Supported operations:"
    echo "  labels"
    echo "  text"
    echo "  faces"
    exit 1
    ;;
esac