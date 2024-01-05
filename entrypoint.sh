#!/bin/bash
set -e

IFACE=$(ip route show default | awk '{print $5}')

if [ ! -e "/opt/wgcf/wgcf-profile.conf" ]; then
    IPv4=$(ifconfig "$IFACE" | awk '/inet /{print $2}' | cut -d' ' -f2)
    IPv6=$(ifconfig "$IFACE" | awk '/inet6 /{print $2}' | cut -d' ' -f2)
    wgcf register --accept-tos && wgcf generate && mv wgcf-profile.conf /opt/wgcf
    sed -i "/\[Interface\]/a PostDown = ip -6 rule delete from ${IPv6}  lookup main" /opt/wgcf/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostUp = ip -6 rule add from ${IPv6} lookup main" /opt/wgcf/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostDown = ip -4 rule delete from ${IPv4} lookup main" /opt/wgcf/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostUp = ip -4 rule add from ${IPv4} lookup main" /opt/wgcf/wgcf-profile.conf
fi

/bin/cp -rf /opt/wgcf/wgcf-profile.conf /etc/wireguard/warp.conf && /bin/cp -rf /opt/wgcf/danted.conf /etc/danted.conf
wg-quick up warp

exec "$@"