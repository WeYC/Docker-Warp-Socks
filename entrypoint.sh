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

init() {
    green "正在初始化..."

    if [ ! -e "/wgcf/wgcf-account.toml" ]; then
        wgcf register --accept-tos
    fi

    if [ ! -e "/wgcf/wgcf-profile.conf" ]; then
        wgcf generate
    fi

    green "优选IP..."
    Endpoint_pref

    green "复制配置文件..."
    cp -rf /wgcf/wgcf-profile.conf /etc/wireguard/warp.conf

    if [[ ! -e /etc/wireguard/warp.conf ]]; then
        echo "warp.conf文件不存在"
        exit 1
    fi

    DEFAULT_GATEWAY_NETWORK_CARD_NAME=$(route | grep default | awk '{print $8}' | head -1)
    DEFAULT_ROUTE_IP=$(ifconfig $DEFAULT_GATEWAY_NETWORK_CARD_NAME | grep "inet " | awk '{print $2}' | sed "s/addr://")

    echo ${DEFAULT_GATEWAY_NETWORK_CARD_NAME}
    echo ${DEFAULT_ROUTE_IP}

    sed -i "/\[Interface\]/a PostDown = ip rule delete from $DEFAULT_ROUTE_IP  lookup main" /etc/wireguard/wgcf.conf
    sed -i "/\[Interface\]/a PostUp = ip rule add from $DEFAULT_ROUTE_IP lookup main" /etc/wireguard/wgcf.conf

    sed -i 's/AllowedIPs = ::/#AllowedIPs = ::/' /etc/wireguard/wgcf.conf
    sed -i '/^Address = \([0-9a-fA-F]\{1,4\}:\)\{7\}[0-9a-fA-F]\{1,4\}\/[0-9]\{1,3\}/s/^/#/' /etc/wireguard/wgcf.conf

    Start
}

# Change_WireGuardProfile_V4() {
#     sed -i 's/AllowedIPs = ::/#AllowedIPs = ::/' /wgcf/wgcf-profile.conf
#     sed -i '/^Address = \([0-9a-fA-F]\{1,4\}:\)\{7\}[0-9a-fA-F]\{1,4\}\/[0-9]\{1,3\}/s/^/#/' /wgcf/wgcf-profile.conf
# }

# Change_WireGuardProfile_V6() {
#     sed -i 's/AllowedIPs = 0.0.0.0/#AllowedIPs = 0.0.0.0/' /etc/wireguard/wgcf.conf
# }

Endpoint_pref() {

    if [[ -e "CloudflareST.tar.gz" ]]; then
        tar -xzf CloudflareST.tar.gz
    else
        echo "CloudflareST.tar.gz 文件不存在"
    fi

    # 取消 Linux 自带的线程限制，以便生成优选 Endpoint IP
    ulimit -n 102400

    Endpoint4

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
        echo "${best_endpoint}"
        sed -i "s/Endpoint = .*/Endpoint = ${best_endpoint}/" wgcf-profile.conf
    fi

    green "最佳 Endpoint IP = $best_endpoint 已设置完毕！"

    # rm -f warp ip.txt
}

Endpoint4() {
    # 生成优选 WARP IPv4 Endpoint IP 段列表
    green "生成优选 WARP IPv4 Endpoint IP 段列表..."
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
        if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 162.159.192.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
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
    green "将生成的 IP 段列表放到 ip.txt 里，待程序优选"
    echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u >ip.txt
}

Start() {
    green "开始运行..."
    wg-quick up warp

    green "wgcf status"
    wgcf status

    echo
    echo "checking network..."
    curl -fs https://www.cloudflare.com/cdn-cgi/trace

    echo
    green "OK, wgcf is up."

    sleep infinity &
    wait
}

green "启动..."
# init
echo "$PWD"
