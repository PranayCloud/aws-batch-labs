# 🖼️ AI Image Visualizer

A web application that extracts text from uploaded images using **AWS Rekognition** and analyzes the sentiment of that text using **AWS Comprehend**. Hosted on an AWS EC2 instance and fully provisioned via CloudFormation.

---

## How It Works

```
User uploads image
       │
       ▼
  S3 Bucket (stores image)
       │
       ▼
  AWS Rekognition (extracts text)
       │
       ▼
  AWS Comprehend (analyzes sentiment)
       │
       ▼
  Results displayed on the same page
```

---

## Project Structure

```
ai-image-visualizer/
├── app/
│   ├── templates/
│   │   └── index.html        # Single-page UI
│   ├── app.py                # Flask application
│   └── requirements.txt      # Python dependencies
├── infrastructure/
│   ├── cloudformation.yaml   # Full AWS infrastructure stack
│   └── userdata.sh           # EC2 bootstrap script
├── deploy.sh                 # One-shot deployment pipeline
└── requirements.md           # Project requirements
```

---

## AWS Services Used

| Service | Purpose |
|---|---|
| EC2 | Hosts the Flask web application |
| S3 | Stores uploaded images and app code |
| Rekognition | Extracts text from images |
| Comprehend | Analyzes sentiment of extracted text |
| CloudFormation | Provisions all infrastructure |
| IAM | Grants EC2 permissions to access AWS services |

---

## Prerequisites

- AWS CLI installed and configured (`aws configure`)
- Bash shell (Git Bash on Windows, Terminal on Mac/Linux)
- Python 3.9+ (for running locally)
- An AWS account with permissions to create EC2, S3, IAM, CloudFormation resources

---

## Running Locally

**1. Install dependencies**
```bash
cd app
pip install -r requirements.txt
```

**2. Set environment variables**

Windows CMD:
```cmd
set APP_BUCKET=your-s3-bucket-name
set AWS_DEFAULT_REGION=us-east-1
```

Git Bash / Mac / Linux:
```bash
export APP_BUCKET=your-s3-bucket-name
export AWS_DEFAULT_REGION=us-east-1
```

**3. Create the S3 bucket if it doesn't exist**
```bash
aws s3api create-bucket --bucket your-s3-bucket-name --region us-east-1
```

**4. Run the app**
```bash
python app.py
```

**5. Open in browser**
```
http://localhost:5000
```

---

## Deploying to AWS

The `deploy.sh` script handles everything end to end:
- Creates the EC2 key pair if it doesn't exist
- Creates the S3 bucket if it doesn't exist
- Packages and uploads app code to S3
- Deploys the CloudFormation stack (VPC, EC2, IAM, Security Group)
- Pushes the latest app code to EC2 and restarts the service

**Run the pipeline:**
```bash
./deploy.sh <key-pair-name> <your-ip-cidr> [availability-zone] [aws-region]
```

**Example:**
```bash
./deploy.sh mykeypair 203.0.113.10/32 us-east-1a us-east-1
```

| Argument | Required | Default | Description |
|---|---|---|---|
| `key-pair-name` | yes | — | EC2 key pair name (created automatically if missing) |
| `your-ip-cidr` | yes | — | Your IP for SSH access e.g. `203.0.113.10/32` |
| `availability-zone` | no | `us-east-1a` | AZ for the public subnet |
| `aws-region` | no | `us-east-1` | AWS region to deploy into |

Once complete, the script prints the app URL:
```
========================================
 Deployment Complete!
========================================
 App URL: http://<EC2-PUBLIC-IP>
========================================
```

> Wait ~60 seconds after deployment for EC2 userdata to finish bootstrapping.

---

## Infrastructure Overview

The CloudFormation stack creates:

- **VPC** with a public subnet and internet gateway
- **Security Group** allowing HTTP (80) from anywhere and SSH (22) from your IP only
- **IAM Role** with least-privilege permissions for S3, Rekognition, and Comprehend
- **EC2 instance** (t3.micro, Amazon Linux 2023) running Flask behind nginx via gunicorn

---

## Teardown

To delete all AWS resources and avoid charges:
```bash
aws cloudformation delete-stack --stack-name ai-image-visualizer --region us-east-1
aws s3 rm s3://your-s3-bucket-name --recursive
aws s3api delete-bucket --bucket your-s3-bucket-name --region us-east-1
```
