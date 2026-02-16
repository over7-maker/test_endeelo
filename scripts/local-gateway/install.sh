#!/bin/bash

# Fortress v3.1 - Local Gateway Installation Script
# يتطلب: Ubuntu 20.04/22.04 أو Debian 11/12
# يعمل كـ: Transparent Proxy + Tor + Unbound DNS + ECMP + Dual Kill Switch

set -e

echo "=== تثبيت Fortress v3.1 - Local Gateway ==="

# التحقق من الصلاحيات
if [ "$EUID" -ne 0 ]; then 
    echo "يرجى تشغيل السكريبت بصلاحيات root"
    exit 1
fi

# متغيرات التكوين - يجب تعديلها حسب بيئتك
LAN_INTERFACE="eth1"  # واجهة الشبكة الداخلية
LAN_SUBNET="192.168.100.0/24"  # شبكة LAN الداخلية
GATEWAY_IP="192.168.100.1"  # IP الـ Gateway

# معلومات VPS - أدخل IPs و Public Keys للـ VPS
VPS1_ENDPOINT=""  # مثال: 1.2.3.4:51820
VPS1_PUBKEY=""     # Public key من VPS Layer 1

VPS_CLEAN_EXIT_ENDPOINT=""  # مثال: 5.6.7.8:51823
VPS_CLEAN_EXIT_PUBKEY=""    # Public key من Clean Exit VPS

# تحديث النظام
echo "تحديث النظام..."
apt update && apt upgrade -y

# تثبيت الحزم الأساسية
apt install -y \
    tor \
    tor-geoipdb \
    obfs4proxy \
    wireguard \
    wireguard-tools \
    unbound \
    iptables \
    iptables-persistent \
    iproute2 \
    dnsutils \
    curl \
    git

# إنشاء مفاتيح WireGuard
echo "إنشاء مفاتيح WireGuard..."
mkdir -p /etc/wireguard
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
WG_PRIVATE=$(cat /etc/wireguard/privatekey)

# إعداد WireGuard - واجهتين (Main VPS + Clean Exit)
cat > /etc/wireguard/wg-main.conf << EOF
[Interface]
PrivateKey = $WG_PRIVATE
Address = 10.0.1.2/24
Table = 1000

[Peer]
PublicKey = $VPS1_PUBKEY
Endpoint = $VPS1_ENDPOINT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

cat > /etc/wireguard/wg-clean.conf << EOF
[Interface]
PrivateKey = $WG_PRIVATE
Address = 10.0.4.2/24
Table = 2000

[Peer]
PublicKey = $VPS_CLEAN_EXIT_PUBKEY
Endpoint = $VPS_CLEAN_EXIT_ENDPOINT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

# إعداد Tor Transparent Proxy
echo "إعداد Tor Transparent Proxy..."
cat > /etc/tor/torrc << 'TOREOF'
# Fortress v3.1 - Tor Transparent Proxy Configuration

VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1

# Transparent Proxy
TransPort 10.0.1.2:9040 IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort
DNSPort 10.0.1.2:5353

# SOCKS5 Proxy
SocksPort 10.0.1.2:9050 IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort

# Control Port
ControlPort 9051

# تدوير Circuit كل 10 دقائق
MaxCircuitDirtiness 600
NewCircuitPeriod 30

# إعدادات الأداء
CircuitBuildTimeout 60
LearnCircuitBuildTimeout 0

# حظر Exit Nodes في بلدان معينة (اختياري)
# ExcludeExitNodes {cn},{ru},{ir}

# بريدجز obfs4 (إن لزم)
UseBridges 0
TOREOF

# إعداد Unbound DNS
echo "إعداد Unbound DNS..."
cat > /etc/unbound/unbound.conf.d/fortress.conf << 'UNBOUNDEOF'
server:
    interface: 10.0.1.2
    access-control: 10.0.0.0/8 allow
    access-control: 192.168.0.0/16 allow
    
    # الخصوصية
    hide-identity: yes
    hide-version: yes
    qname-minimisation: yes
    
    # DNSSEC
    auto-trust-anchor-file: "/var/lib/unbound/root.key"
    
    # Forward إلى Tor DNS
    do-not-query-localhost: no
    
forward-zone:
    name: "."
    forward-addr: 10.0.1.2@5353
UNBOUNDEOF

# إعداد ECMP Routing (توزيع الحركة بين Main و Clean Exit)
echo "إعداد ECMP Routing..."

# إعداد Routing Tables
echo "100 main_vpn" >> /etc/iproute2/rt_tables
echo "200 clean_vpn" >> /etc/iproute2/rt_tables

# سكريبت ECMP rotation (5 دقائق)
cat > /usr/local/bin/fortress-ecmp.sh << 'ECMPEOF'
#!/bin/bash
# ECMP Rotation Script - يتم تنفيذه كل 5 دقائق

# حذف القواعد القديمة
ip rule del table main_vpn 2>/dev/null || true
ip rule del table clean_vpn 2>/dev/null || true
ip route del default 2>/dev/null || true

# تبديل بين Main VPN و Clean Exit VPN بشكل عشوائي
if [ $((RANDOM % 2)) -eq 0 ]; then
    # استخدام Main VPN
    ip route add default dev wg-main table 100
    ip rule add from all lookup 100 priority 100
    echo "[$(date)] Switched to Main VPN" >> /var/log/fortress-ecmp.log
else
    # استخدام Clean Exit VPN
    ip route add default dev wg-clean table 200
    ip rule add from all lookup 200 priority 100
    echo "[$(date)] Switched to Clean Exit VPN" >> /var/log/fortress-ecmp.log
fi
ECMPEOF

chmod +x /usr/local/bin/fortress-ecmp.sh

# جدولة cron لتبديل ECMP كل 5 دقائق
echo "*/5 * * * * /usr/local/bin/fortress-ecmp.sh" | crontab -

# تفعيل IP forwarding
echo "تفعيل IP forwarding..."
cat >> /etc/sysctl.conf << SYSCTLEOF

# Fortress v3.1 Settings
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=0
net.ipv6.conf.default.forwarding=0
net.ipv6.conf.all.disable_ipv6=1

# تحسينات الأداء
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
SYSCTLEOF

sysctl -p

# === إعداد DUAL KILL SWITCH ===
echo "إعداد Dual Kill Switch..."

# مسح جميع القواعد الحالية
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# === Kill Switch Level 1: السياسة الافتراضية - DROP ===
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# السماح بـ loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# السماح بـ established/related connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# السماح بالحركة من LAN
iptables -A INPUT -i $LAN_INTERFACE -s $LAN_SUBNET -j ACCEPT
iptables -A FORWARD -i $LAN_INTERFACE -s $LAN_SUBNET -j ACCEPT

# === Kill Switch Level 2: السماح فقط عبر WireGuard و Tor ===

# السماح بـ WireGuard واجهات
iptables -A OUTPUT -o wg-main -j ACCEPT
iptables -A OUTPUT -o wg-clean -j ACCEPT

# السماح بحركة Tor
iptables -A OUTPUT -m owner --uid-owner debian-tor -j ACCEPT

# السماح بـ DHCP للـ LAN
iptables -A INPUT -i $LAN_INTERFACE -p udp --dport 67:68 -j ACCEPT
iptables -A OUTPUT -o $LAN_INTERFACE -p udp --dport 67:68 -j ACCEPT

# === Transparent Proxy Rules ===

# إعادة توجيه DNS إلى Unbound
iptables -t nat -A PREROUTING -i $LAN_INTERFACE -p udp --dport 53 -j DNAT --to-destination 10.0.1.2:53
iptables -t nat -A PREROUTING -i $LAN_INTERFACE -p tcp --dport 53 -j DNAT --to-destination 10.0.1.2:53

# إعادة توجيه حركة HTTP/HTTPS إلى Tor TransPort
iptables -t nat -A PREROUTING -i $LAN_INTERFACE -p tcp --syn -j DNAT --to-destination 10.0.1.2:9040

# MASQUERADE للحركة الخارجة
iptables -t nat -A POSTROUTING -o wg-main -j MASQUERADE
iptables -t nat -A POSTROUTING -o wg-clean -j MASQUERADE

# === حظر تسرب DNS ===
iptables -A OUTPUT ! -o lo ! -d 127.0.0.1 -p udp --dport 53 -j DROP
iptables -A OUTPUT ! -o lo ! -d 127.0.0.1 -p tcp --dport 53 -j DROP

# حفظ القواعد
netfilter-persistent save

echo "Dual Kill Switch مفعّل!"

# تفعيل الخدمات
echo "تفعيل الخدمات..."

systemctl enable wg-quick@wg-main
systemctl enable wg-quick@wg-clean
systemctl start wg-quick@wg-main
systemctl start wg-quick@wg-clean

systemctl enable tor
systemctl start tor

systemctl enable unbound
systemctl start unbound

# تشغيل ECMP لأول مرة
/usr/local/bin/fortress-ecmp.sh

# عرض المعلومات
echo ""
echo "============================================"
echo "=== اكتمل تثبيت Fortress v3.1 ==="
echo "============================================"
echo ""
echo "WireGuard Public Key:"
cat /etc/wireguard/publickey
echo ""
echo "ملاحظات مهمة:"
echo "1. عدّل /etc/wireguard/wg-main.conf و /etc/wireguard/wg-clean.conf"
echo "   بإضافة Public Keys و Endpoints للـ VPS"
echo ""
echo "2. أعد تشغيل WireGuard:"
echo "   systemctl restart wg-quick@wg-main"
echo "   systemctl restart wg-quick@wg-clean"
echo ""
echo "3. تحقق من حالة الخدمات:"
echo "   systemctl status wg-quick@wg-main"
echo "   systemctl status wg-quick@wg-clean"
echo "   systemctl status tor"
echo "   systemctl status unbound"
echo ""
echo "4. ميزات الأمان المفعّلة:"
echo "   ✓ Dual Kill Switch (مستويين)"
echo "   ✓ Tor Transparent Proxy (3 hops + 10min rotation)"
echo "   ✓ ECMP Load Balancing (تبديل كل 5 دقائق)"
echo "   ✓ Unbound DNS عبر Tor"
echo "   ✓ حظر تسرب DNS"
echo ""
echo "5. لوجات ECMP:"
echo "   tail -f /var/log/fortress-ecmp.log"
echo ""
echo "============================================"
