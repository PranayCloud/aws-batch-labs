#!/bin/bash

aws s3 cp "images/$1" "s3://test-aws-august-ai-weekend-batch/$1" --region us-east-1

aws rekognition detect-faces \
    --image "S3Object={Bucket=test-aws-august-ai-weekend-batch, Name=$1}" \
    --region us-east-1 \
    --attributes ALL \
    --query "FaceDetails[].{Gender:Gender.Value,GenderConfidence:Gender.Confidence,AgeLow:AgeRange.Low,AgeHigh:AgeRange.High,Smile:Smile.Value,SmileConfidence:Smile.Confidence,Emotions:Emotions[0].Type,EmotionConfidence:Emotions[0].Confidence,EyesOpen:EyesOpen.Value,MouthOpen:MouthOpen.Value}" \
    --output table