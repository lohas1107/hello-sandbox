IMAGE              ?= vscode-insiders-sandbox:latest
WORKSPACE          ?= $(CURDIR)
VSCODE_TUNNEL_NAME ?=

TUNNEL_FLAGS       := --accept-server-license-terms $(if $(VSCODE_TUNNEL_NAME),--name "$(VSCODE_TUNNEL_NAME)",)

.PHONY: help build load-sbx run tunnel

help:
	@echo "可用指令："
	@echo "  make tunnel    在 Sandbox 內啟動 VS Code Insiders Remote Tunnel"
	@echo "  make build     本地建置 Sandbox 映像檔 ($(IMAGE))"
	@echo "  make load-sbx  將本地映像檔匯入至 sbx image store"
	@echo "  make run       使用本地映像檔啟動 Docker Sandbox"

tunnel:
	code-insiders tunnel $(TUNNEL_FLAGS)

build:
	docker build -t $(IMAGE) .

load-sbx: build
	@TMP_TAR=$$(mktemp /tmp/vscode-insiders-sandbox.XXXXXX.tar); \
	trap 'rm -f "$$TMP_TAR"' EXIT; \
	docker image save $(IMAGE) -o "$$TMP_TAR"; \
	sbx template load "$$TMP_TAR"

run:
	@if command -v sbx >/dev/null 2>&1; then \
		sbx run --pull never -t $(IMAGE) shell $(WORKSPACE); \
	else \
		docker sandbox run --template $(IMAGE) shell $(WORKSPACE); \
	fi
