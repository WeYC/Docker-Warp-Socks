#!/bin/bash

set -e

osCheck=$(uname -a)
echo "ARCHITECTURE: $osCheck"
if [[ $osCheck =~ 'x86_64' ]];then
    architecture="amd64"
elif [[ $osCheck =~ 'arm64' ]] || [[ $osCheck =~ 'aarch64' ]];then
    architecture="arm64"
elif [[ $osCheck =~ 'armv7l' ]];then
    architecture="armv7"
elif [[ $osCheck =~ 'ppc64le' ]];then
    architecture="ppc64le"
elif [[ $osCheck =~ 's390x' ]];then
    architecture="s390x"
else
    echo "暂不支持的系统架构，选择受支持的系统。"
    exit 1
fi

TAR="https://api.github.com/repos/XIU2/CloudflareSpeedTest/releases/latest"

URL=$(curl -fsSL ${TAR} | grep 'browser_download_url' | cut -d'"' -f4 | grep linux | grep "${architecture}")

echo "${URL}"

curl -sSL "${URL}" -o /opt/wgcf/CloudflareST.tar.gz

exec "$@"