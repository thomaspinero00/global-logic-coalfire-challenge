#!/bin/bash
yum update -y
yum install -y httpd unzip

# Instalar AWS CLI v2
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

systemctl start httpd
systemctl enable httpd
echo "Hello from ASG instance $(hostname)" > /var/www/html/index.html