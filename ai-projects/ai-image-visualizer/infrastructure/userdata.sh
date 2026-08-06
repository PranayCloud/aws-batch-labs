#!/bin/bash
set -e

APP_BUCKET="__APP_BUCKET__"
APP_DIR="/home/ec2-user/app"

yum update -y
yum install -y python3 python3-pip nginx
pip3 install flask boto3 gunicorn

# Pull app code from S3
aws s3 cp s3://${APP_BUCKET}/app.tar.gz /home/ec2-user/app.tar.gz
tar -xzf /home/ec2-user/app.tar.gz -C /home/ec2-user/

# Fetch region using IMDSv2
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/region)

# Write environment file so systemd passes vars to gunicorn
cat > /etc/ai-visualizer.env <<EOF
APP_BUCKET=${APP_BUCKET}
AWS_DEFAULT_REGION=${INSTANCE_REGION}
EOF

# Create systemd service for gunicorn
cat > /etc/systemd/system/ai-visualizer.service <<EOF
[Unit]
Description=AI Image Visualizer (gunicorn)
After=network.target

[Service]
User=ec2-user
WorkingDirectory=${APP_DIR}
EnvironmentFile=/etc/ai-visualizer.env
ExecStart=/usr/local/bin/gunicorn -w 2 -b 127.0.0.1:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Configure nginx as reverse proxy
cat > /etc/nginx/conf.d/app.conf <<'EOF'
server {
    listen 80;
    client_max_body_size 20M;
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF
rm -f /etc/nginx/conf.d/default.conf

# Start services
systemctl daemon-reload
systemctl enable ai-visualizer
systemctl start ai-visualizer
systemctl enable nginx
systemctl restart nginx
