#!/bin/bash
set -eou pipefail

echo "Installing Amazon SSM Agent using snap..."
sudo snap start amazon-ssm-agent
sudo snap services amazon-ssm-agent

echo "Installing Nginx"
sudo apt update
sudo apt install -y nginx

echo "Enable Nginx"
sudo systemctl enable nginx
sudo systemctl start nginx