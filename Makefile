IMAGE     ?= vscode-insiders-sandbox:latest
AGENT     ?= shell
WORKSPACE ?= $(CURDIR)

.PHONY: help build load-sbx run run-image

help:
	@echo "可用宿主機指令："
	@echo "  make run        使用本地 Kit 目錄 (--kit .) 啟動 Docker Sandbox (進入沙盒後執行 vscode-tunnel)"
	@echo "  make build      本地建置 Sandbox Kit OCI 映像檔 ($(IMAGE))"
	@echo "  make load-sbx   將本地 Kit 映像檔匯入至 sbx image store"
	@echo "  make run-image  使用已建置/匯入的 Kit 映像檔 (--kit $(IMAGE)) 啟動 Docker Sandbox"

build:
	docker buildx build -f spec.yaml -t $(IMAGE) --load .

load-sbx: build
	@TMP_TAR=$$(mktemp /tmp/vscode-insiders-sandbox.XXXXXX.tar); \
	trap 'rm -f "$$TMP_TAR"' EXIT; \
	docker image save $(IMAGE) -o "$$TMP_TAR"; \
	sbx template load "$$TMP_TAR"

run:
	@if command -v sbx >/dev/null 2>&1; then \
		sbx run --kit $(CURDIR) $(AGENT) $(WORKSPACE); \
	else \
		docker sandbox run --kit $(CURDIR) $(AGENT) $(WORKSPACE); \
	fi

run-image:
	@if command -v sbx >/dev/null 2>&1; then \
		sbx run --pull never --kit $(IMAGE) $(AGENT) $(WORKSPACE); \
	else \
		docker sandbox run --kit $(IMAGE) $(AGENT) $(WORKSPACE); \
	fi
