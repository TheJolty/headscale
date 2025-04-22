#!/bin/bash
set -eou pipefail

echo "Installing Amazon SSM Agent using snap..."
sudo snap start amazon-ssm-agent
sudo snap services amazon-ssm-agent

echo "Downloading Go..."
curl -O -L "https://golang.org/dl/go${GO_VERSION}.linux-${DERP_ARCH}.tar.gz"
echo "Checking Go SHA256 checksum..."
CHECKSUM=$(curl -sL https://golang.org/dl/ | grep -A 5 -w "go${GO_VERSION}.linux-${DERP_ARCH}.tar.gz" | grep -oP '(?<=<tt>)[a-f0-9]{64}(?=</tt>)')
echo -n "$CHECKSUM *go${GO_VERSION}.linux-${DERP_ARCH}.tar.gz" | shasum -a 256 --check

echo "Installing Go..."
sudo tar -xf "go${GO_VERSION}.linux-${DERP_ARCH}.tar.gz"
sudo chown -R root:root ./go
mv go/bin/go /usr/local/bin/
mv -v go /usr/local
export GOPATH=/root/go
echo "export GOPATH=/root/go" >> ~/.bashrc
export GOROOT=/usr/local/go
echo "export GOROOT=/usr/local/go" >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
echo "export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin" >> ~/.bashrc
export HOME=/root

echo "Installing DERP..."
go install tailscale.com/cmd/derper@${DERP_VERSION}
derper --hostname=${DERP_HOSTNAME}

echo "Done"
