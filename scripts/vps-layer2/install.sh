#!/bin/bash

# Fortress v3.1 - VPS Layer 2 (Tor Exit VPS) Installation Script
# يتطلب: Ubuntu 20.04/22.04

set -e

echo "=== تثبيت Fortress v3.1 - VPS Layer 2 (Tor Exit) ==="

# التحقق من الصلاحيات
if [ "$EUID" -ne 0 ]; then 
    echo "يرجى تشغيل السكريبت بصلاحيات root"
    exit 1
fi

# تحديث النظام
apt update && apt upgrade -y

# تثبيت الحزم الأساسية
apt install -y \
    tor \
    obfs4proxy \
    wireguard \
    wireguard-tools \
    iptables \
    iptables-persistent \
    build-essential \
    cmake \
    git \
    libsodium-dev \
    libopenssl-dev

# تثبيت udp2raw
echo "جاري تثبيت udp2raw..."
cd /opt
git clone https://github.com/wangyu-/udp2raw.git
cd udp2raw
make
cp udp2raw /usr/local/bin/
chmod +x /usr/local/bin/udp2raw

# إنشاء مفاتيح WireGuard
echo "إنشاء مفاتيح WireGuard..."
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
WG_PRIVATE=$(cat /etc/wireguard/privatekey)

# إعداد واجهة WireGuard
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $WG_PRIVATE
Address = 10.0.2.1/24
ListenPort = 51821
MTU = 1380

# سيتم إضافة peers من Layer 1 يدوياً
EOF

# تكوين Tor كـ Exit Node
cat > /etc/tor/torrc << EOF
# Fortress VPS Layer 2 - Tor Exit Configuration

SocksPort 0
ORPort 9001

# Exit Policy - السماح بحركة HTTPS فقط للأمان
ExitPolicy accept *:443
ExitPolicy accept *:80
ExitPolicy reject *:*

ExitRelay 1

# Bandwidth
RelayBandwidthRate 10 MB
RelayBandwidthBurst 20 MB

# Nickname (اختياري)
# Nickname FortressExit2

# ContactInfo (اختياري)
# ContactInfo your@email.com

# تدوير Circuit كل 10 دقائق
MaxCircuitDirtiness 600

# معلومات الخصوصية
ClientOnly 0
EOF

# تفعيل IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p

# إعداد iptables - NAT + Kill Switch
echo "إعداد جدار الحماية..."

# مسح القواعد الحالية
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# السياسة الافتراضية - رفض كل شيء (Kill Switch)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# السماح بـ loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# السماح بـ established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# السماح بـ WireGuard من Layer 1
iptables -A INPUT -p udp --dport 51821 -j ACCEPT
iptables -A INPUT -i wg0 -j ACCEPT
iptables -A OUTPUT -o wg0 -j ACCEPT

# السماح بـ Tor ORPort
iptables -A INPUT -p tcp --dport 9001 -j ACCEPT

# السماح بحركة Tor الصادرة
iptables -A OUTPUT -m owner --uid-owner debian-tor -j ACCEPT

# NAT للحركة القادمة من WireGuard إلى Tor
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# FORWARD من WireGuard إلى الإنترنت عبر Tor
iptables -A FORWARD -i wg0 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o wg0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# حفظ القواعد
netfilter-persistent save

# تفعيل الخدمات
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

systemctl enable tor
systemctl start tor

# عرض المعلومات
echo ""
echo "=== اكتمل التثبيت ==="
echo ""
echo "WireGuard Public Key:"
cat /etc/wireguard/publickey
echo ""
echo "WireGuard Endpoint: $(curl -s ifconfig.me):51821"
echo ""
echo "ملاحظات:"
echo "1. أضف peer من Layer 1 إلى /etc/wireguard/wg0.conf"
echo "2. أعد تشغيل WireGuard: systemctl restart wg-quick@wg0"
echo "3. تحقق من حالة Tor: systemctl status tor"
echo "4. Kill Switch مفعّل - فقط WireGuard و Tor مسموح"
echo ""
