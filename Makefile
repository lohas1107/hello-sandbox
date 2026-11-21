KITS      ?= vscode-insiders antigravity ai-gateway
SETS      ?= shell-vscode-insiders-set antigravity-vscode-insiders-set
KIT       ?= vscode-insiders
TAG       ?= latest
AGENT     ?= docker.io/docker/sbx-kit-shell:1.0.0
WORKSPACE ?= $(CURDIR)

.PHONY: help validate build build-all env-plan env-run run run-antigravity

help:
	@echo "可用宿主機指令："
	@echo "  make validate         驗證本地所有 Kits (kits/*) 與實驗性 Kit (experimental/*)"
	@echo "  make build            本地建置單一 Kit OCI 映像檔 (預設 KIT=$(KIT), TAG=$(TAG))"
	@echo "  make build-all        本地建置所有 Kits ($(KITS))"
	@echo "  make env-plan         預覽根目錄 sbxenv.yaml 將建立的沙盒環境設定"
	@echo "  make env-run          依據根目錄 sbxenv.yaml 啟動並進入沙盒環境"
	@echo "  make run              使用本地 kits/vscode-insiders 疊加於 $(AGENT) 啟動沙盒"
	@echo "  make run-antigravity  使用本地 kits/antigravity workload + kits/vscode-insiders 啟動沙盒"

validate:
	@for k in $(KITS); do \
		echo "==> Validating kits/$$k"; \
		sbx kit validate "$(CURDIR)/kits/$$k"; \
	done
	@for e in $(CURDIR)/experimental/*; do \
		if [ -d "$$e" ]; then \
			echo "==> Validating $$e"; \
			sbx kit validate "$$e"; \
		fi; \
	done

build:
	docker buildx build -f kits/$(KIT)/$(KIT).yaml -t sbx-kit-$(KIT):$(TAG) --load kits/$(KIT)

build-all:
	@for k in $(KITS); do \
		echo "==> Building sbx-kit-$$k:$(TAG)"; \
		$(MAKE) build KIT=$$k TAG=$(TAG); \
	done

env-plan:
	sbx env plan

env-run:
	sbx env run

run:
	@if command -v sbx >/dev/null 2>&1; then \
		sbx run --kit "$(CURDIR)/kits/vscode-insiders" $(AGENT) "$(WORKSPACE)"; \
	else \
		docker sandbox run --kit "$(CURDIR)/kits/vscode-insiders" $(AGENT) "$(WORKSPACE)"; \
	fi

run-antigravity:
	@if command -v sbx >/dev/null 2>&1; then \
		sbx run --kit "$(CURDIR)/kits/vscode-insiders" "$(CURDIR)/kits/antigravity" "$(WORKSPACE)"; \
	else \
		docker sandbox run --kit "$(CURDIR)/kits/vscode-insiders" "$(CURDIR)/kits/antigravity" "$(WORKSPACE)"; \
	fi
