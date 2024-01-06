FROM ubuntu:focal

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="Asia/Shanghai"

RUN apt-get -qq update \
    && apt-get -qq install curl net-tools \
    && apt-get -qq install --no-install-recommends dante-server wireguard-tools iproute2 procps iptables openresolv kmod \
    && apt-get -qq autoremove --purge && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL git.io/wgcf.sh | bash

RUN mkdir -p /opt/wgcf

WORKDIR /opt/wgcf

VOLUME /opt/wgcf

COPY download.sh /tmp/download.sh
RUN chmod +x /tmp/download.sh && /tmp/download.sh

COPY entrypoint.sh /run/entrypoint.sh
RUN chmod +x /run/entrypoint.sh

ENTRYPOINT ["/run/entrypoint.sh"]
