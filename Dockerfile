FROM node:24-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV NPM_CONFIG_REGISTRY=https://registry.npmmirror.com
ENV DSH_HOME=/data/dsh

# 官方 Debian 源实测 20KB/s，换腾讯云镜像；
# 必须 http，slim 镜像内无 ca-certificates，https 会证书校验失败
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

# 原生模块编译工具链：node-pty、koffi、dsh-subprocess-local
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 make g++ ca-certificates git curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/dsh

# 安装官方发布包 + 批准依赖脚本 + 强制重编译原生模块 + 构建期自检
RUN npm init -y >/dev/null \
 && npm install @deepseek-ai/dsh@0.2.2-rc.3 --no-audit --no-fund \
 && (npm install-scripts approve node-pty koffi @deepseek-ai/dsh-subprocess-local protobufjs || true) \
 && npm rebuild --foreground-scripts node-pty koffi @deepseek-ai/dsh-subprocess-local \
 && node -e "require('node-pty'); require('koffi'); console.log('native modules OK')"

RUN mkdir -p /data/dsh

EXPOSE 3080

CMD ["sh", "-c", "exec ./node_modules/.bin/dsh web --host $(hostname -i | awk '{print $1}') --port 3080 --no-open ${DSH_PUBLIC_URL:+--public-url $DSH_PUBLIC_URL} ${DSH_TRUSTED_HOST:+--trusted-host $DSH_TRUSTED_HOST}"]
