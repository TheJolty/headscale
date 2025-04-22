#!/bin/bash
set -eou pipefail

echo "Installing Amazon SSM Agent using snap..."
sudo snap start amazon-ssm-agent
sudo snap services amazon-ssm-agent

echo "Installing basic packages..."
snap install aws-cli --classic
apt-get update
apt install -y wget curl git

echo "Installing Tailscale client..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "Retrieving Subnet Router PreAuthorized Keys from Parameter Store..."
timeout=120 # 2 minutes
start_time=$(date +%s)
while true; do
  AUTH_KEY=$(aws ssm get-parameter --with-decryption --name "${PRE_AUTH_KEY_PARAMETER}" --query "Parameter.Value" --output text)

  # Check if the value is a 48-character alphanumeric password
  if [[ "$AUTH_KEY" =~ ^[a-zA-Z0-9]{48}$ ]]; then
    break
  else
    echo "Waiting SSM Parameter have a valid value..."
  fi

  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))

  if [[ $elapsed_time -ge $timeout ]]; then
      echo "Timeout reached. Parameter Store value is not a pre-auth key!"
      echo "Check if something went wrong during Headscale user_data script installation!"
      exit 1
  fi

  sleep 5
done

# https://tailscale.com/kb/1019/subnets?tab=linux#enable-ip-forwarding
echo "Enable IP forwarding"
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

# https://tailscale.com/kb/1320/performance-best-practices#ethtool-configuration
echo "Optimizations for Linux"
NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
sudo ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off
printf '#!/bin/sh\n\nethtool -K %s rx-udp-gro-forwarding on rx-gro-list off \n' "$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")" | sudo tee /etc/networkd-dispatcher/routable.d/50-tailscale
sudo chmod 755 /etc/networkd-dispatcher/routable.d/50-tailscale
sudo /etc/networkd-dispatcher/routable.d/50-tailscale
test $? -eq 0 || echo 'An error occurred.'

echo "Install dnsmasq"
sudo apt update
cat <<EOF > /etc/dnsmasq.conf
server=/internal/169.254.169.253
server=1.1.1.1
listen-address=127.0.0.1,${SUBNET_ROUTER_PRIVATE_IP}
no-resolv
EOF
# sudo apt install -y dnsmasq
sudo apt install -y dnsmasq \
  -o Dpkg::Options::="--force-confold" \
  -o Dpkg::Options::="--force-confdef"
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm /etc/resolv.conf
echo "nameserver 169.254.169.253" | sudo tee /etc/resolv.conf
systemctl start dnsmasq
systemctl restart dnsmasq
systemctl status dnsmasq


echo "Connecting to Tailscale server..."
tailscale up --login-server https://${HEADSCALE_HOSTNAME} --advertise-routes=${VPC_CIDR} \
  --accept-dns=false --authkey $AUTH_KEY

echo "Done"