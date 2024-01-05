#!/bin/bash
set -e

echo "${PWD}"

IFACE=$(ip route show default | awk '{print $5}')
IPv4=$(ifconfig "$IFACE" | awk '/inet /{print $2}' | cut -d' ' -f2)
IPv6=$(ifconfig "$IFACE" | awk '/inet6 /{print $2}' | cut -d' ' -f2)

if [ ! -e "/opt/wgcf/wgcf-account.toml" ]; then
    wgcf register --accept-tos
fi

if [ ! -e "/opt/wgcf/wgcf-profile.conf" ]; then
    wgcf generate
fi

sed -i "/\[Interface\]/a PostDown = ip -6 rule delete from ${IPv6}  lookup main" /opt/wgcf/wgcf-profile.conf
sed -i "/\[Interface\]/a PostUp = ip -6 rule add from ${IPv6} lookup main" /opt/wgcf/wgcf-profile.conf
sed -i "/\[Interface\]/a PostDown = ip -4 rule delete from ${IPv4} lookup main" /opt/wgcf/wgcf-profile.conf
sed -i "/\[Interface\]/a PostUp = ip -4 rule add from ${IPv4} lookup main" /opt/wgcf/wgcf-profile.conf

/bin/cp -rf /opt/wgcf/wgcf-profile.conf /etc/wireguard/warp.conf

wg-quick up warp

echo "wgcf status"
wgcf status

echo
echo "OK, wgcf is up."

sleep infinity &
wait

exec "$@"
