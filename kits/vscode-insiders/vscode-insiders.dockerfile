FROM debian:bookworm-slim AS build

ARG TARGETARCH

# 安裝下載與解壓縮 code-insiders CLI 所需的最小工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    gzip \
    && rm -rf /var/lib/apt/lists/*

# 自動偵測架構 (支援 BUILDKIT TARGETARCH 或執行期 uname -m) 並安裝 code-insiders CLI 與全域 vscode-tunnel 啟動指令
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
        amd64) \
            VSCODE_OS="cli-alpine-x64"; \
            MULTIARCH_LIBDIR="/usr/lib/x86_64-linux-gnu" \
            ;; \
        arm64) \
            VSCODE_OS="cli-alpine-arm64"; \
            MULTIARCH_LIBDIR="/usr/lib/aarch64-linux-gnu" \
            ;; \
        *) echo "Unsupported TARGETARCH: $ARCH" >&2; exit 1 ;; \
    esac; \
    mkdir -p /out/usr/local/bin /out/usr/lib64; \
    ln -s "${MULTIARCH_LIBDIR}/libstdc++.so.6" /out/usr/lib64/libstdc++.so.6; \
    curl -fsSL "https://code.visualstudio.com/sha/download?build=insider&os=${VSCODE_OS}" \
        | tar -xz -C /out/usr/local/bin; \
    chmod +x /out/usr/local/bin/code-insiders; \
    /out/usr/local/bin/code-insiders --version; \
    printf '%s\n' \
        '#!/bin/sh' \
        'set -eu' \
        'if [ ! -s /etc/ld.so.cache ] && [ -x /sbin/ldconfig ]; then' \
        '    if [ "$(id -u)" -eq 0 ]; then' \
        '        /sbin/ldconfig 2>/dev/null || true' \
        '    elif command -v sudo >/dev/null 2>&1; then' \
        '        sudo -n /sbin/ldconfig 2>/dev/null || true' \
        '    fi' \
        'fi' \
        'if [ -n "${VSCODE_TUNNEL_NAME:-}" ]; then' \
        '    exec /usr/local/bin/code-insiders tunnel --accept-server-license-terms --name "$VSCODE_TUNNEL_NAME" "$@"' \
        'else' \
        '    exec /usr/local/bin/code-insiders tunnel --accept-server-license-terms "$@"' \
        'fi' \
        > /out/usr/local/bin/vscode-tunnel; \
    chmod +x /out/usr/local/bin/vscode-tunnel

FROM scratch
COPY --from=build /out/ /
