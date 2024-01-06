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

    endpoint_pref

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

endpoint_pref() {
    # 下载优选工具软件，感谢某匿名网友的分享的优选工具
    # wget https://gitlab.com/Misaka-blog/warp-script/-/raw/main/files/warp-yxip/warp-linux-$(archAffix) -O warp
    TAR="https://api.github.com/repos/XIU2/CloudflareSpeedTest/releases/latest"
    ARCH=$(ArchAffix)
    echo "${ARCH}"
    URL=$(curl -fsSL ${TAR} | grep 'browser_download_url' | cut -d'"' -f4 | grep linux | grep "$(ArchAffix)")
    echo "${URL}"

    tar -xzf CloudflareST.tar.gz

    # 取消 Linux 自带的线程限制，以便生成优选 Endpoint IP
    ulimit -n 102400

    endpoint4

    # 启动 WARP Endpoint IP 优选工具
    chmod +x CloudflareST && ./CloudflareST >/dev/null 2>&1

    green "当前最优 Endpoint IP 结果如下，并已保存至 result.csv中："
    cat result.csv | awk -F, '$3!="timeout ms" {print} ' | sort -t, -nk2 -nk3 | uniq | head -11 | awk -F, '{print "端点 "$1" 丢包率 "$2" 平均延迟 "$3}'
    # 将 result.csv 文件的优选 Endpoint IP 提取出来，放置到 best_endpoint 变量中备用
    best_endpoint=$(cat result.csv | sed -n 2p | awk -F ',' '{print $1}')
    echo ""
    echo "${best_endpoint}"
    echo
    # 查询优选出来的 Endpoint IP 的 loss 是否为 100.00%，如是，则替换为默认的 Endpoint IP
    endpoint_loss=$(cat result.csv | sed -n 2p | awk -F ',' '{print $2}')
    if [[ $endpoint_loss == "100.00%" ]]; then
        yellow "优选失败"
    else
        yellow "优选成功"
        # 替换 WireGuard 节点的默认的 Endpoint IP
        sed -i "s|Endpoint = .*|Endpoint = $best_endpoint|" wgcf-profile.conf
    fi

    green "最佳 Endpoint IP = $best_endpoint 已设置完毕！"

    # yellow "使用方法如下："
    # yellow "1. 将 WireGuard 节点的默认的 Endpoint IP：engage.cloudflareclient.com:2408 替换成本地网络最优的 Endpoint IP"
    # sed -i "s/engage.cloudflareclient.com:2408/$best_endpoint/g" /etc/wireguard/wgcf.conf
    # sed -i "/Endpoint/s/.*/Endpoint = "$best_endpoint"/" warp.conf
    # 删除 WARP Endpoint IP 优选工具及其附属文件
    # rm -f warp ip.txt
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
    echo "checking network..."
    curl -fs https://www.cloudflare.com/cdn-cgi/trace

    echo
    green "OK, wgcf is up."

    sleep infinity
    wait
}

if command -v wgcf >/dev/null 2>&1; then
    init
else
    exec "$@"
fi
