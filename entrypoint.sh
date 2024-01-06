#!/bin/bash

set -e

red() {
    echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
    echo -e "\033[33m\033[01m$1\033[0m"
}

# 检查是否以ROOT用户运行
if [ "$(id -u)" -ne 0 ]; then
    red "请使用ROOT用户运行此脚本。"
    exit 1
fi

ArchAffix() {
    case "$(uname -m)" in
    i386 | i686) echo '386' ;;
    x86_64 | amd64) echo 'amd64' ;;
    armv8 | arm64 | aarch64) echo 'arm64' ;;
    arm*) echo "armv7" ;;
    s390x) echo 's390x' ;;
    *) red "不支持的CPU架构!" && exit 1 ;;
    esac
}

# 检测 VPS 的出站 IP
check_ip() {
    ipv4=$(curl -s4m10 ipinfo.io/ip -k)
    ipv6=$(curl -s6m10 v6.ipinfo.io/ip -k)
}

init() {
    check_ip
    if [[ -n ${ipv4} || -n ${ipv6} ]]; then
        red "无网络连接"
        exit 1
    fi
    IFACE=$(ip route show default | awk '{print $5}')
    IPv4=$(ifconfig "$IFACE" | awk '/inet /{print $2}' | cut -d' ' -f2)
    IPv6=$(ifconfig "$IFACE" | awk '/inet6 /{print $2}' | cut -d' ' -f2)

    if [ ! -e "/opt/wgcf/wgcf-account.toml" ]; then
        wgcf register --accept-tos
    fi

    if [ ! -e "/opt/wgcf/wgcf-profile.conf" ]; then
        wgcf generate
    fi

    Change_WireGuardProfile_V4
    Change_WireGuardProfile_V6
    
    cp -rf /opt/wgcf/wgcf-profile.conf /etc/wireguard/warp.conf

    start
}

Change_WireGuardProfile_V4() {
    sed -i "/\[Interface\]/a PostDown = ip -4 rule delete from ${IPv4} lookup main" /opt/wgcf/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostUp = ip -4 rule add from ${IPv4} lookup main" /opt/wgcf/wgcf-profile.conf
}

Change_WireGuardProfile_V6() {
    sed -i "/\[Interface\]/a PostDown = ip -6 rule delete from ${IPv6}  lookup main" /opt/wgcf/wgcf-profile.conf
    sed -i "/\[Interface\]/a PostUp = ip -6 rule add from ${IPv6} lookup main" /opt/wgcf/wgcf-profile.conf
}

Endpoint4() {
    # 生成优选 WARP IPv4 Endpoint IP 段列表
    n=0
    iplist=100
    while true; do
        temp[$n]=$(echo 162.159.192.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo 162.159.193.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo 162.159.195.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo 162.159.204.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo 188.114.96.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo 188.114.97.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo 188.114.98.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo 188.114.99.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
    done
    while true; do
        if [[ $(echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]]; then
            break
        else
            temp["${n}"]=$(echo 162.159.192.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [[ $(echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]]; then
            break
        else
            temp[$n]=$(echo 162.159.193.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 162.159.195.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 162.159.204.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 188.114.96.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 188.114.97.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 188.114.98.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 188.114.99.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
    done

    # 将生成的 IP 段列表放到 ip.txt 里，待程序优选
    echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u >ip.txt
}

Start() {
    wg-quick up warp

    green "wgcf status"
    wgcf status

    echo
    green "OK, wgcf is up."

    sleep infinity
    wait
}

if ! wg-quick down wgcf; then
    init
else
    exec "$@"
fi
