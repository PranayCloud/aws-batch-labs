#!/bin/bash

# =====================================================
# Amazon Transcribe End-to-End Demo
# Upload Audio -> S3 -> Transcribe -> S3 Output
# Download JSON -> Display Transcript
# =====================================================

BUCKET_NAME="tes-aws-july-batch-bucket"
REGION="us-east-1"

AUDIO_FILE="$1"

echo "========================================"
echo " Amazon Transcribe Speech-to-Text Demo"
echo "========================================"

# Validate input
if [ $# -ne 1 ]; then
    echo "Usage: $0 <audio-file>"
    exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
    echo "Audio file not found!"
    exit 1
fi

FILE_NAME=$(basename "$AUDIO_FILE")
JOB_NAME="TranscriptionJob-$(date +%s)"

echo ""
echo "Uploading audio to S3..."

aws s3 cp "$AUDIO_FILE" "s3://$BUCKET_NAME/$FILE_NAME" --region $REGION

if [ $? -ne 0 ]; then
    echo "Upload Failed."
    exit 1
fi

echo "Upload Successful."

echo ""
echo "Starting Transcription Job..."

aws transcribe start-transcription-job \
    --transcription-job-name "$JOB_NAME" \
    --language-code en-US \
    --media MediaFileUri="s3://$BUCKET_NAME/$FILE_NAME" \
    --output-bucket-name "$BUCKET_NAME" \
    --region "$REGION"

if [ $? -ne 0 ]; then
    echo "Failed to start transcription job."
    exit 1
fi

echo "Job Name : $JOB_NAME"

echo ""
echo "Waiting for transcription to complete..."

aws transcribe wait transcription-job-completed \
    --transcription-job-name "$JOB_NAME" \
    --region "$REGION"

echo "Transcription Completed."

echo ""
echo "Downloading transcript JSON from S3..."

aws s3 cp \
"s3://$BUCKET_NAME/$JOB_NAME.json" \
"./$JOB_NAME.json" \
--region "$REGION"

if [ $? -ne 0 ]; then
    echo "Failed to download transcript."
    exit 1
fi

echo "Transcript downloaded."

echo ""
echo "==============================="
echo "Recognized Speech"
echo "==============================="

TRANSCRIPT=$(python extract-transcript.py "$JOB_NAME.json")

echo "$TRANSCRIPT"

echo ""
echo "==============================="
echo "Transcription Completed Successfully"
echo "==============================="

echo "Sentiment analysis is being performed on the transcript..."

SENTIMENT=$(aws comprehend detect-sentiment \
    --text "$TRANSCRIPT" \
    --language-code en \
    --region "$REGION" \
    --query "Sentiment" \
    --output text)

echo "Sentiment: $SENTIMENT"

