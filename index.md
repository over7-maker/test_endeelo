fortress-v3.1/
├── README.md                          # دليل التثبيت الشامل
├── scripts/
│   ├── 00-prepare-environment.sh      # تحضير البيئة
│   ├── 01-install-operator.sh         # تثبيت كامل للـ Operator
│   ├── 02-install-vps.sh              # تثبيت كامل للـ VPS (يُنفذ على كل VPS)
│   ├── 03-configure-router.sh         # تكوين الراوتر (OpenWRT)
│   └── 04-test-system.sh              # اختبار شامل
├── operator/
│   ├── config/
│   │   ├── wireguard/
│   │   │   ├── wg-t1.conf
│   │   │   ├── wg-t2.conf
│   │   │   ├── wg-t3.conf
│   │   │   └── wg-cx.conf
│   │   ├── tor/
│   │   │   └── torrc
│   │   ├── unbound/
│   │   │   └── unbound.conf
│   │   ├── iptables/
│   │   │   ├── tor-transparent.rules
│   │   │   ├── killswitch.rules
│   │   │   └── policy-routing.rules
│   │   ├── udp2raw/
│   │   │   ├── udp2raw-t1.conf
│   │   │   ├── udp2raw-t2.conf
│   │   │   ├── udp2raw-t3.conf
│   │   │   └── udp2raw-cx.conf
│   │   └── ipset/
│   │       └── nostor.list
│   ├── daemons/
│   │   ├── ecmp-daemon.py
│   │   └── hybrid-key-daemon.py
│   └── systemd/
│       ├── ecmp-daemon.service
│       ├── hybrid-key-daemon.service
│       ├── udp2raw-t1.service
│       ├── udp2raw-t2.service
│       ├── udp2raw-t3.service
│       └── udp2raw-cx.service
├── vps/
│   ├── config/
│   │   ├── wireguard/
│   │   │   └── wg0.conf.template
│   │   ├── udp2raw/
│   │   │   └── udp2raw-server.conf.template
│   │   ├── sysctl/
│   │   │   └── forwarding.conf
│   │   └── firewall/
│   │       └── vps-firewall.sh
│   └── systemd/
│       └── udp2raw-server.service
├── router/
│   ├── config/
│   │   ├── firewall.user
│   │   ├── dhcp.conf
│   │   └── network.conf
│   └── scripts/
│       └── apply-killswitch.sh
└── tools/
    ├── generate-keys.sh               # توليد مفاتيح WireGuard
    ├── update-nostor-list.sh          # تحديث قائمة nostor
    ├── test-leaks.sh                  # اختبار التسريبات
    ├── monitor-status.sh              # مراقبة الحالة
    └── restart-all.sh                 # إعادة تشغيل كاملة
