# syntax=docker/dockerfile:1
FROM docker.io/docker/sbx-kit-shell:1.0.0

ARG TARGETARCH

USER root
RUN set -eux; \
    ARCH="${TARGETARCH:-}"; \
    if [ -z "$ARCH" ]; then \
        case "$(uname -m)" in \
            x86_64|amd64) ARCH="amd64" ;; \
            aarch64|arm64) ARCH="arm64" ;; \
            *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
        esac; \
    fi; \
    PLATFORM="linux_${ARCH}"; \
    MANIFEST_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/${PLATFORM}.json"; \
    MANIFEST_JSON="$(curl -fsSL "$MANIFEST_URL")"; \
    URL="$(printf '%s' "$MANIFEST_JSON" | jq -r '.url')"; \
    SHA512="$(printf '%s' "$MANIFEST_JSON" | jq -r '.sha512')"; \
    TMP_DIR="$(mktemp -d)"; \
    curl -fsSL "$URL" -o "$TMP_DIR/agy.tar.gz"; \
    echo "${SHA512}  $TMP_DIR/agy.tar.gz" | sha512sum -c -; \
    tar -xzf "$TMP_DIR/agy.tar.gz" -C "$TMP_DIR" antigravity; \
    install -m 0755 "$TMP_DIR/antigravity" /usr/local/bin/agy; \
    ln -sfn /usr/local/bin/agy /usr/local/bin/antigravity; \
    rm -rf "$TMP_DIR"; \
    /usr/local/bin/agy --version

USER agent
WORKDIR /home/agent/workspace
ENTRYPOINT ["agy", "--dangerously-skip-permissions"]
