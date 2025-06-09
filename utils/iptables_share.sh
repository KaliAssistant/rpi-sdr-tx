#!/usr/bin/env bash
set -e

# name of the ethernet gadget interface on the host
USB_IFACE=${1:-enx486f73745043}
USB_IFACE_NET=172.16.48.0/24
# host interface to use for upstream connection
UPSTREAM_IFACE=${2:-eth0}

iptables -A FORWARD -o "$UPSTREAM_IFACE" -i "$USB_IFACE" -s "$USB_IFACE_NET" -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -o "$UPSTREAM_IFACE" -j MASQUERADE

echo 1 > /proc/sys/net/ipv4/ip_forward
