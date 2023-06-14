#!/bin/bash -e

function print_help() {
    echo "Usage: $0 <IDENTITY_FILE> <INSTANCE_IP> [FLAGS]"
    echo ""
    echo "FLAGS:"
    echo "    --skip-packages-install"
}

if [[ $# -lt 2 ]]; then
  print_help  
  exit
fi

IDENTITY_FILE=$1
INSTANCE_IP=$2

if [ -z $3 ]; then
    SKIP_PACKAGES_INSTALL="false"
else
    if [[ "$3" == "--skip-packages-install" ]]; then
        SKIP_PACKAGES_INSTALL="true"
    else
        print_help
        exit
    fi
fi

if [[ "$SKIP_PACKAGES_INSTALL" == "false" ]]; then
    echo "Install packages"
    {
        sudo apt-get update
        sudo apt-get install -y wireguard resolvconf
    } >> logs
fi

echo "Configure server"
scp -i "$IDENTITY_FILE" vpn-server.sh "ubuntu@$INSTANCE_IP:"
ssh -i "$IDENTITY_FILE" "ubuntu@$INSTANCE_IP" bash vpn-server.sh

echo "Configure client"
ssh -i "$IDENTITY_FILE" "ubuntu@$INSTANCE_IP" cat client.conf | sudo tee /opt/homebrew/etc/wireguard/wg0.conf
wg-quick up wg0

echo "Run tests"
./test-connection.sh
