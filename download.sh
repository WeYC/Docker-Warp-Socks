#!/bin/bash

set -o errexit
set -o errtrace
set -o pipefail

PROJECT_NAME='warp'
GH_API_URL='https://api.github.com/repos/XIU2/CloudflareSpeedTest/releases/latest'
BIN_DIR='/usr/local/bin'
BIN_NAME='warp'
BIN_FILE="${BIN_DIR}/${BIN_NAME}"

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

URL=$(curl -fsSL ${GH_API_URL} | grep 'browser_download_url' | cut -d'"' -f4 | grep linux | grep "$(ArchAffix)")

echo "${URL}"

curl -SL "${URL}" -o CloudflareST.tar.gz

if [[ -e CloudflareST.tar.gz ]]; then
    echo "Download success"
    tar -xzf CloudflareST.tar.gz
    mv CloudflareST ${BIN_NAME}
else
    echo "Download failed"
fi
ls -a
chmod +x ${BIN_NAME}
