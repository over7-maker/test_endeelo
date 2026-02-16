#!/bin/bash

# Fortress v3.1 - Clean Exit VPS Installation Script

set -e

echo "========================================"
echo "Fortress v3.1 - Clean Exit VPS Setup"
echo "========================================"

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

echo "[1/7] Updating system..."
apt-get update && apt-get upgrade -y

echo "[2/7] Installing packages..."
apt-get install -y tor obfs4proxy wireguard wireguard-tools \
    iptables iptables-persistent ufw fail2ban \
    prometheus-node-exporter unbound

echo "[3/7] Configuring Tor..."
cat > /etc/tor/torrc << EOF
# Fortress v3.1 - Tor Configuration
SocksPort 0
ControlPort 9051
CookieAuthentication 1

# Transparent Proxy
TransPort 127.0.0.1:9040 IsolateClientAddr IsolateClientProtocol
DNSPort 127.0.0.1:5353

# Entry Guards
NumEntryGuards 3
GuardLifetime 90 days

# Circuit Management
CircuitBuildTimeout 60
LearnCircuitBuildTimeout 0
MaxCircuitDirtiness 600
NewCircuitPeriod 600

# obfs4 Bridge (add your bridges here)
# UseBridges 1
# ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy
# Bridge obfs4 [IP:PORT] [FINGERPRINT] cert=[CERT] iat-mode=0

# Performance
NumCPUs 2
AvoidDiskWrites 1
EOF

systemctl enable tor
systemctl restart tor

echo "[4/7] Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 51820/udp
ufw allow 22/tcp
ufw allow 9100/tcp
ufw --force enable

# Transparent proxy iptables rules
iptables -t nat -A PREROUTING -i wg0 -p tcp --syn -j REDIRECT --to-ports 9040
iptables -t nat -A PREROUTING -i wg0 -p udp --dport 53 -j REDIRECT --to-ports 5353
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

echo "[5/7] Generating WireGuard keys..."
mkdir -p /etc/wireguard
cd /etc/wireguard
wg genkey | tee privatekey | wg pubkey > publickey
chmod 600 privatekey

echo "[6/7] Configuring sysctl..."
cat > /etc/sysctl.d/99-fortress.conf << EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

sysctl -p /etc/sysctl.d/99-fortress.conf

echo "[7/7] Starting services..."
systemctl enable prometheus-node-exporter
systemctl start prometheus-node-exporter

echo ""
echo "========================================"
echo "Installation complete!"
echo "========================================"
echo ""
echo "Configure WireGuard in /etc/wireguard/wg0.conf"
echo "Public Key: $(cat /etc/wireguard/publickey)"
echo ""
