FROM docker/sandbox-templates:shell

ARG TARGETARCH

USER root

# 安裝最小基礎工具與 make (供沙盒內執行 make tunnel)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    gzip \
    make \
    && rm -rf /var/lib/apt/lists/*

# 自動偵測架構 (支援 BUILDKIT TARGETARCH 或執行期 uname -m) 並安裝 code-insiders CLI
RUN set -eux; \
    ARCH="${TARGETARCH:-}"; \
    if [ -z "$ARCH" ]; then \
        case "$(uname -m)" in \
            x86_64) ARCH="amd64" ;; \
            aarch64|arm64) ARCH="arm64" ;; \
            *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
        esac; \
    fi; \
    case "$ARCH" in \
        amd64) VSCODE_OS="cli-alpine-x64" ;; \
        arm64) VSCODE_OS="cli-alpine-arm64" ;; \
        *) echo "Unsupported TARGETARCH: $ARCH" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://code.visualstudio.com/sha/download?build=insider&os=${VSCODE_OS}" \
        | tar -xz -C /usr/local/bin; \
    chmod +x /usr/local/bin/code-insiders; \
    /usr/local/bin/code-insiders --version

ENV HOME=/home/agent \
    PATH="/home/agent/.local/bin:/usr/local/bin:${PATH}"

USER agent
WORKDIR /home/agent/workspace
