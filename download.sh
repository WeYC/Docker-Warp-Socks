#!/bin/bash

set -e

echo "$PWD"

ArchAffix() {
    case "$(uname -m)" in
    i386 | i686) echo '386' ;;
    x86_64 | amd64) echo 'amd64' ;;
    armv8 | arm64 | aarch64) echo 'arm64' ;;
    arm*) echo "armv7" ;;
    s390x) echo 's390x' ;;
    *) echo "不支持的CPU架构!" && exit 1 ;;
    esac
}

TAR="https://api.github.com/repos/XIU2/CloudflareSpeedTest/releases/latest"

URL=$(curl -fsSL ${TAR} | grep 'browser_download_url' | cut -d'"' -f4 | grep linux | grep "$(ArchAffix)")

echo "${URL}"

curl -fsSL "${URL}" -o CloudflareST.tar.gz

if [[ -e CloudflareST.tar.gz ]]; then
    echo "Download success"
    tar -xzf CloudflareST.tar.gz
else
    echo "Download failed"
fi

exec "$@"
