#!/bin/bash
set -eou pipefail

echo "Installing Amazon SSM Agent using snap..."
sudo snap start amazon-ssm-agent
sudo snap services amazon-ssm-agent

echo "Installing basic packages..."
snap install aws-cli --classic
apt-get update
apt install -y wget curl git

echo "Downloading Headscale DEB file..."
wget --output-document=headscale.deb \
  "https://github.com/juanfont/headscale/releases/download/v${HEADSCALE_VERSION}/headscale_${HEADSCALE_VERSION}_linux_${HEADSCALE_ARCH}.deb"

echo "Installing Headscale server..."
sudo apt install ./headscale.deb

echo "Creating Headscale manifest..."
cat <<EOF > /etc/headscale/config.yaml
${HEADSCALE_CONFIG}
EOF

cat <<EOF > /etc/headscale/derp.yaml
${DERP_MAP}
EOF

echo "Enabling Headscale service using systemctl..."
sudo systemctl enable --now headscale
sudo systemctl start headscale
sudo systemctl status headscale

echo "Creating Pre-Authorized Keys for Subnet Router and pushing it to Parameter store..."
SUBNET_ROUTER_USER=subnet-router
headscale users create $SUBNET_ROUTER_USER
SUBNET_ROUTER_PRE_AUTH_KEY=$(headscale preauthkeys create --user $SUBNET_ROUTER_USER --reusable --expiration 24h)
aws ssm put-parameter --name "${PRE_AUTH_KEY_PARAMETER}" --value "$SUBNET_ROUTER_PRE_AUTH_KEY" --type "SecureString" --overwrite

echo "Creating API Key for Headscale Admin (GUI) and pushing it to Parameter store..."
HEADSCALE_ADMIN_API_KEY=$(headscale apikey create)
aws ssm put-parameter --name "${HEADSCALE_ADMIN_PARAMETER}" --value "$HEADSCALE_ADMIN_API_KEY" --type "SecureString" --overwrite

echo "Installing NodeJS and NPM..."
curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh
bash nodesource_setup.sh
apt-get install -y nodejs
node -v

echo "Building Headscale Admin (GUI)"
git clone --depth 1 --branch v${HEADSCALE_ADMIN_VERSION} https://github.com/GoodiesHQ/headscale-admin
export ENDPOINT="/admin"
cd headscale-admin
npm install -D vite
npm run build
mkdir -p /var/headscale-admin
mv build/* /var/headscale-admin/

echo "Installing Caddy..."
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install -y caddy

echo "Configuring Caddyfile..."
mkdir -p /var/caddy
cat <<EOF > /etc/caddy/Caddyfile
${CADDYFILE}
EOF

systemctl enable caddy
systemctl stop caddy
systemctl start caddy

echo "Done"