#!/bin/bash

# Fortress v3.1 - VPS Layer 1 Installation Script
# For VPS 1-3 (Routing Layer)

set -e

echo "========================================"
echo "Fortress v3.1 - Layer 1 VPS Setup"
echo "========================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Update system
echo "[1/8] Updating system..."
apt-get update && apt-get upgrade -y

# Install required packages
echo "[2/8] Installing packages..."
apt-get install -y wireguard wireguard-tools iptables iptables-persistent \
    build-essential git curl wget unbound ufw fail2ban \
    prometheus-node-exporter udp2raw-tunnel

# Configure firewall
echo "[3/8] Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 51820/udp  # WireGuard
ufw allow 22/tcp     # SSH
ufw allow 9100/tcp   # Node Exporter
ufw --force enable

# Generate WireGuard keys
echo "[4/8] Generating WireGuard keys..."
mkdir -p /etc/wireguard
cd /etc/wireguard
wg genkey | tee privatekey | wg pubkey > publickey
chmod 600 privatekey

echo "Private Key: $(cat privatekey)"
echo "Public Key: $(cat publickey)"

# Configure sysctl for routing
echo "[5/8] Configuring kernel parameters..."
cat > /etc/sysctl.d/99-fortress.conf << EOF
# Enable IP forwarding
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# TCP BBR
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# Security
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
EOF

sysctl -p /etc/sysctl.d/99-fortress.conf

# Setup Unbound DNS
echo "[6/8] Configuring Unbound DNS..."
systemctl stop systemd-resolved
systemctl disable systemd-resolved

cat > /etc/unbound/unbound.conf << EOF
server:
    interface: 127.0.0.1
    port: 53
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    access-control: 127.0.0.0/8 allow
    verbosity: 1
    hide-identity: yes
    hide-version: yes
    
forward-zone:
    name: "."
    forward-tls-upstream: yes
    forward-addr: 1.1.1.1@853#cloudflare-dns.com
    forward-addr: 1.0.0.1@853#cloudflare-dns.com
EOF

systemctl enable unbound
systemctl restart unbound

# Setup fail2ban
echo "[7/8] Configuring fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

# Enable services
echo "[8/8] Enabling services..."
systemctl enable prometheus-node-exporter
systemctl start prometheus-node-exporter

echo ""
echo "========================================"
echo "Installation complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Configure WireGuard interface in /etc/wireguard/wg0.conf"
echo "2. Start WireGuard: systemctl enable wg-quick@wg0 && systemctl start wg-quick@wg0"
echo "3. Configure ECMP routing"
echo ""
echo "Your WireGuard public key:"
cat /etc/wireguard/publickey
echo ""
