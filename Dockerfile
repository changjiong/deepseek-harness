FROM node:24-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV NPM_CONFIG_REGISTRY=https://registry.npmmirror.com
ENV DSH_HOME=/data/dsh

# 官方 Debian 源在本机实测仅 20KB/s，换腾讯云镜像；
# 必须用 http 协议，因为 slim 镜像内还没有 ca-certificates，https 会证书校验失败
RUN set -eux; \
    if [ -f /etc/apt/sources.list.d/debian.sources ]; then \
      sed -i 's|deb.debian.org|mirrors.cloud.tencent.com|g; \
              s|security.debian.org|mirrors.cloud.tencent.com|g; \
              s|https://mirrors.cloud.tencent.com|http://mirrors.cloud.tencent.com|g' \
        /etc/apt/sources.list.d/debian.sources; \
    fi; \
    if [ -f /etc/apt/sources.list ]; then \
      sed -i 's|deb.debian.org|mirrors.cloud.tencent.com|g; \
              s|security.debian.org|mirrors.cloud.tencent.com|g' \
        /etc/apt/sources.list; \
    fi

# 编译 node-pty / koffi 等原生模块所需工具链
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 make g++ ca-certificates git curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/dsh

# 直接安装官方发布包，不构建源码，规避 monorepo 在 2C7G 上的 OOM 风险
RUN npm init -y >/dev/null \
 && npm install @deepseek-ai/dsh@0.2.2-rc.3 --no-audit --no-fund

RUN mkdir -p /data/dsh

EXPOSE 3080

# dsh 拒绝绑定 0.0.0.0，必须传具体网卡 IP
CMD ["sh", "-c", "exec ./node_modules/.bin/dsh web --host $(hostname -i | awk '{print $1}') --port 3080 --no-open"]
