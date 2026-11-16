FROM node:24-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV NPM_CONFIG_REGISTRY=https://registry.npmmirror.com
ENV DSH_HOME=/data/dsh

RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 make g++ ca-certificates git curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/dsh

RUN npm init -y >/dev/null \
 && npm install @deepseek-ai/dsh@0.2.2-rc.3 --no-audit --no-fund \
 && (npm install-scripts approve node-pty koffi @deepseek-ai/dsh-subprocess-local protobufjs || true) \
 && (npm rebuild node-pty koffi || true)

RUN mkdir -p /data/dsh

EXPOSE 3080

CMD ["sh", "-c", "exec ./node_modules/.bin/dsh web --host $(hostname -i | awk '{print $1}') --port 3080 --no-open ${DSH_PUBLIC_URL:+--public-url $DSH_PUBLIC_URL} ${DSH_TRUSTED_HOST:+--trusted-host $DSH_TRUSTED_HOST}"]
