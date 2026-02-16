#!/bin/bash

# Fortress v3.1 - Status Monitoring Script
# يتحقق من حالة جميع الخدمات والاتصالات

echo "===================================="
echo "  Fortress v3.1 - System Status"
echo "===================================="
echo ""

# فحص WireGuard
echo "[✓] فحص WireGuard:"
if systemctl is-active --quiet wg-quick@wg-main; then
    echo "  ✔ wg-main: نشط"
    wg show wg-main | grep -E 'interface|peer|endpoint|latest handshake'
else
    echo "  ✘ wg-main: متوقف"
fi

if systemctl is-active --quiet wg-quick@wg-clean 2>/dev/null; then
    echo "  ✔ wg-clean: نشط"
    wg show wg-clean | grep -E 'interface|peer|endpoint|latest handshake'
else
    echo "  ✘ wg-clean: متوقف أو غير معرّف"
fi
echo ""

# فحص Tor
echo "[✓] فحص Tor:"
if systemctl is-active --quiet tor; then
    echo "  ✔ Tor: نشط"
    # عرض Circuit الحالي
    echo "  دوائر Tor النشطة:"
    netstat -tulpn 2>/dev/null | grep -E '9040|9050|5353' || echo "    لا يوجد معلومات"
else
    echo "  ✘ Tor: متوقف"
fi
echo ""

# فحص Unbound DNS
echo "[✓] فحص Unbound DNS:"
if systemctl is-active --quiet unbound; then
    echo "  ✔ Unbound: نشط"
    echo "  اختبار DNS:"
    dig +short @10.0.1.2 check.torproject.org 2>/dev/null && echo "    ✔ DNS يعمل" || echo "    ✘ DNS لا يعمل"
else
    echo "  ✘ Unbound: متوقف"
fi
echo ""

# فحص Kill Switch
echo "[✓] فحص Kill Switch:"
iptables -L -n | grep -q "DROP" && echo "  ✔ Kill Switch مفعّل" || echo "  ✘ Kill Switch غير مفعّل"
echo ""

# فحص IP الخارجي
echo "[✓] فحص IP الخارجي:"
EXTERNAL_IP=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null)
if [ -n "$EXTERNAL_IP" ]; then
    echo "  IP الخارجي: $EXTERNAL_IP"
    echo "  اختبار Tor:"
    TOR_CHECK=$(curl -s --max-time 5 https://check.torproject.org/api/ip 2>/dev/null)
    if echo "$TOR_CHECK" | grep -q '"IsTor":true'; then
        echo "    ✔ أنت متصل عبر Tor"
    else
        echo "    ✘ لست متصلاً عبر Tor"
    fi
else
    echo "  ✘ فشل في الحصول على IP الخارجي"
fi
echo ""

# فحص ECMP
echo "[✓] فحص ECMP:"
if [ -f "/var/log/fortress-ecmp.log" ]; then
    echo "  آخر تبديل:"
    tail -n 1 /var/log/fortress-ecmp.log
else
    echo "  ✘ لم يتم العثور على لوج ECMP"
fi
echo ""

echo "===================================="
