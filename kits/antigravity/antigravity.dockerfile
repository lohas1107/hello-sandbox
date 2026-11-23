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

RUN set -eux; \
    usermod -s /bin/bash agent; \
    touch /etc/shells; \
    for sh in /bin/sh /bin/bash /usr/bin/bash; do \
        grep -qxF "$sh" /etc/shells || echo "$sh" >> /etc/shells; \
    done; \
    for f in .bashrc .profile .bash_logout; do \
        if [ -f "/etc/skel/$f" ]; then \
            cp -a "/etc/skel/$f" "/home/agent/$f"; \
            chown agent:agent "/home/agent/$f"; \
        fi; \
    done

ENV SHELL=/bin/bash

USER agent
WORKDIR /home/agent/workspace
ENTRYPOINT ["agy", "--dangerously-skip-permissions"]
