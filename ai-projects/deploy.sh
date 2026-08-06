#!/bin/bash
# ============================================================
# AI Image Visualizer - Deployment Pipeline
# Usage: ./deploy.sh <key-pair-name> <your-ip-cidr> [az] [aws-region]
# ============================================================
set -euo pipefail

BUCKET="test-aws-s3-ai-project-buck"
KEY_PAIR="${1:?Usage: $0 <key-pair-name> <your-ip-cidr> [az] [aws-region]}"
SSH_CIDR="${2:?Usage: $0 <key-pair-name> <your-ip-cidr> [az] [aws-region]}"
AZ="${3:-us-east-1a}"
REGION="${4:-us-east-1}"
STACK_NAME="ai-image-visualizer"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo " AI Image Visualizer - Deployment Start"
echo "========================================"
echo "Bucket  : $BUCKET"
echo "Region  : $REGION"
echo "Stack   : $STACK_NAME"
echo "========================================"

# ── Step 0: Ensure EC2 key pair exists ──────────────────────
echo ""
echo "[0/4] Checking EC2 key pair: $KEY_PAIR..."
if aws ec2 describe-key-pairs --key-names "$KEY_PAIR" --region "$REGION" 2>/dev/null | grep -q "$KEY_PAIR"; then
  echo "  Key pair already exists: $KEY_PAIR"
else
  echo "  Key pair not found. Creating: $KEY_PAIR"
  aws ec2 create-key-pair \
    --key-name "$KEY_PAIR" \
    --region "$REGION" \
    --query 'KeyMaterial' \
    --output text > "$SCRIPT_DIR/$KEY_PAIR.pem"
  chmod 400 "$SCRIPT_DIR/$KEY_PAIR.pem"
  echo "  Key pair created. PEM saved to: $SCRIPT_DIR/$KEY_PAIR.pem"
fi

# ── Step 1: Ensure S3 bucket exists ──────────────────────────
echo ""
echo "[1/5] Ensuring S3 bucket exists..."
if aws s3api head-bucket --bucket "$BUCKET" --region "$REGION" 2>/dev/null; then
  echo "  Bucket already exists: $BUCKET"
else
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  echo "  Created bucket: $BUCKET"
fi

# ── Step 2: Package and upload app code ──────────────────────
echo ""
echo "[2/5] Packaging and uploading app code to S3..."
cd "$SCRIPT_DIR"
tar -czf /tmp/app.tar.gz app/
aws s3 cp /tmp/app.tar.gz "s3://$BUCKET/app.tar.gz" --region "$REGION"
echo "  Uploaded app.tar.gz to s3://$BUCKET/app.tar.gz"

# ── Step 3: Prepare userdata & deploy CloudFormation stack ──
echo ""
echo "[3/5] Deploying CloudFormation stack: $STACK_NAME..."

# Read userdata.sh, substitute bucket placeholder, then base64-encode
USERDATA=$(sed "s|__APP_BUCKET__|$BUCKET|g" "$SCRIPT_DIR/infrastructure/userdata.sh" | base64 | tr -d '\n')

aws cloudformation deploy \
  --template-file "$SCRIPT_DIR/infrastructure/cloudformation.yaml" \
  --stack-name "$STACK_NAME" \
  --parameter-overrides \
      AppBucketName="$BUCKET" \
      KeyPairName="$KEY_PAIR" \
      SSHLocation="$SSH_CIDR" \
      AvailabilityZone="$AZ" \
      UserDataScript="$USERDATA" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "$REGION"

echo "  Stack deployed successfully."

# ── Step 4: Retrieve EC2 public IP & sync app code ──────────
echo ""
echo "[4/5] Retrieving EC2 public IP..."
PUBLIC_IP=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='PublicIP'].OutputValue" \
  --output text)

echo "  Public IP: $PUBLIC_IP"

# ── Step 5: Push latest app code to EC2 & restart service ────
echo ""
echo "[5/5] Pushing latest app code to EC2..."
PEM="$SCRIPT_DIR/$KEY_PAIR.pem"
SSH_OPTS="-i $PEM -o StrictHostKeyChecking=no -o ConnectTimeout=30"

# Wait for SSH to be ready
echo "  Waiting for SSH..."
for i in $(seq 1 20); do
  ssh $SSH_OPTS ec2-user@"$PUBLIC_IP" exit 2>/dev/null && break
  sleep 5
done

scp $SSH_OPTS -r "$SCRIPT_DIR/app/" ec2-user@"$PUBLIC_IP":/home/ec2-user/
ssh $SSH_OPTS ec2-user@"$PUBLIC_IP" "sudo systemctl restart ai-visualizer"
echo "  App code synced and service restarted."

echo ""
echo "========================================"
echo " Deployment Complete!"
echo "========================================"
echo " App URL: http://$PUBLIC_IP"
echo " (Wait ~60s for EC2 userdata to finish)"
echo "========================================"
