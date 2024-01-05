#!/bin/bash

set -e

IFACE=$(ip route show default | awk '{print $5}')
IPv4=$(ifconfig "$IFACE" | awk '/inet /{print $2}' | cut -d' ' -f2)
IPv6=$(ifconfig "$IFACE" | awk '/inet6 /{print $2}' | cut -d' ' -f2)
a=0

init() {
    echo "初始化..."

    echo "${IFACE}"
    echo "${IPv4}"
    echo "${IPv6}"

    if ! wg-quick down wgcf; then
        echo "wgcf下载不成功"
        exit 1
    fi

    if [ ! -e "wgcf-account.toml" ]; then
        wgcf register --accept-tos
    fi

    if [ ! -e "wgcf-profile.conf" ]; then
        wgcf generate
    fi

    sed -i "/\[Interface\]/a PostDown = ip -6 rule delete from ${IPv6}  lookup main" /opt/wgcf/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostUp = ip -6 rule add from ${IPv6} lookup main" /opt/wgcf/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostDown = ip -4 rule delete from ${IPv4} lookup main" /opt/wgcf/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostUp = ip -4 rule add from ${IPv4} lookup main" /opt/wgcf/wgcf-profile.conf

    cp -rf /opt/wgcf/wgcf-profile.conf /etc/wireguard/warp.conf

    wg-quick up wgcf
}

if [ -z "$@" ]; then
    init "$@"
else
    exec "$@"
fi
