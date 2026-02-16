# Fortress v3.1 - Network Topology

## نظرة عامة على البنية التحتية للشبكة

```
[أجهزة المستخدم]
      |
      | LAN: 192.168.100.0/24
      |
  [Local Gateway]
      |
      +--- WireGuard wg-main (10.0.1.2) --> [VPS Layer 1]
      |                                          |
      |                                    Tor Relay
      |                                          |
      |                                    udp2raw + WireGuard (10.0.2.1) --> [VPS Layer 2]
      |                                                                             |
      |                                                                       Tor Exit Node
      |                                                                             |
      |                                                                       WireGuard (10.0.3.1) --> [VPS Layer 3]
      |                                                                                                     |
      |                                                                                               Tor Exit Node
      |                                                                                                     |
      |                                                                                                 Internet
      |
      +--- WireGuard wg-clean (10.0.4.2) --> [Clean Exit VPS]
                                                    |
                                              Tor Exit Node
                                                    |
                                                Internet
```

## مكونات النظام

### 1. Local Gateway
- **الوظيفة**: Transparent Proxy + Tor + DNS + ECMP
- **IP الداخلي**: 192.168.100.1
- **الخدمات**:
  - Tor Transparent Proxy (Port 9040)
  - Tor SOCKS5 (Port 9050)
  - Tor DNS (Port 5353)
  - Unbound DNS (Port 53)
  - WireGuard wg-main (10.0.1.2)
  - WireGuard wg-clean (10.0.4.2)

### 2. VPS Layer 1 (Tor Relay)
- **الوظيفة**: Tor Relay + udp2raw
- **WireGuard**: 10.0.1.1 (Endpoint: PUBLIC_IP:51820)
- **الخدمات**:
  - Tor Relay (Port 9001)
  - udp2raw server
  - WireGuard to Layer 2

### 3. VPS Layer 2 (Tor Exit)
- **الوظيفة**: Tor Exit Node
- **WireGuard**: 10.0.2.1 (Endpoint: PUBLIC_IP:51821)
- **الخدمات**:
  - Tor Exit Node (Port 9001)
  - Exit Policy: HTTPS/HTTP only
  - WireGuard to Layer 3

### 4. VPS Layer 3 (Tor Exit)
- **الوظيفة**: Tor Exit Node (Final)
- **WireGuard**: 10.0.3.1 (Endpoint: PUBLIC_IP:51822)
- **الخدمات**:
  - Tor Exit Node (Port 9001)
  - Exit Policy: HTTPS/HTTP only

### 5. Clean Exit VPS
- **الوظيفة**: Clean Tor Exit (ECMP Backup)
- **WireGuard**: 10.0.4.1 (Endpoint: PUBLIC_IP:51823)
- **الخدمات**:
  - Tor Exit Node (Port 9001)
  - يستخدم عبر ECMP rotation

## إعدادات WireGuard

### Local Gateway
```ini
# /etc/wireguard/wg-main.conf
[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.0.1.2/24
Table = 1000

[Peer]
PublicKey = VPS1_PUBLIC_KEY
Endpoint = VPS1_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

```ini
# /etc/wireguard/wg-clean.conf
[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.0.4.2/24
Table = 2000

[Peer]
PublicKey = CLEAN_VPS_PUBLIC_KEY
Endpoint = CLEAN_VPS_IP:51823
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

## مسار الحركة

### Main Path (Heavy-Duty)
```
المستخدم --> Local Gateway (Tor Transparent) 
           --> WireGuard (wg-main) 
           --> VPS Layer 1 (Tor Relay + udp2raw)
           --> VPS Layer 2 (Tor Exit)
           --> VPS Layer 3 (Tor Exit)
           --> Internet
```

**مجموع Tor Hops**: 3 + 3 = 6 hops

### Clean Exit Path
```
المستخدم --> Local Gateway (Tor Transparent)
           --> WireGuard (wg-clean)
           --> Clean Exit VPS (Tor Exit)
           --> Internet
```

**مجموع Tor Hops**: 3 + 1 = 4 hops

## ECMP Load Balancing

- **التبديل**: كل 5 دقائق
- **الطريقة**: Random selection between Main & Clean
- **الهدف**: تنويع مسارات الحركة

## Dual Kill Switch

### Level 1: iptables Policy
```bash
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
```

### Level 2: Whitelist Only
- السماح فقط لـ:
  - WireGuard interfaces (wg-main, wg-clean)
  - Tor process (debian-tor user)
  - loopback interface
  - Established connections

## المنافذ والبروتوكولات

| الخدمة | Port | البروتوكول |
|--------|------|------------|
| WireGuard Main | 51820 | UDP |
| WireGuard Layer 2 | 51821 | UDP |
| WireGuard Layer 3 | 51822 | UDP |
| WireGuard Clean | 51823 | UDP |
| Tor ORPort | 9001 | TCP |
| Tor TransPort | 9040 | TCP |
| Tor SOCKS5 | 9050 | TCP |
| Tor DNSPort | 5353 | UDP/TCP |
| Unbound DNS | 53 | UDP/TCP |
