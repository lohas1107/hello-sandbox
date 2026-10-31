# hello-sandbox (VS Code Insiders Docker Sandbox Kit)

基於 **Docker Sandbox Kit v3 (`kind: mixin`)** 規範打造的輕量級擴充套件（Mixin Kit）。可透過 `--kit` 掛載至官方 `shell` 或任意 AI Agent 沙盒（如 `claude`、`codex`、`gemini` 等），自動注入跨架構（`linux/amd64`、`linux/arm64`）的 **VS Code Insiders CLI (`code-insiders`)**、全域啟動指令 **`vscode-tunnel`**，以及 Remote Tunnel 所需的宣告式網路白名單。

## 專案特色

- **極輕量 Mixin Kit (`FROM scratch`)**：僅打包 `/usr/local/bin/code-insiders` 與 `/usr/local/bin/vscode-tunnel`，不綁死特定基底映像檔，可疊加於 `shell` 或任何 Agent 沙盒。
- **宣告式網路白名單 (`network-policy@2`)**：於 [`spec.yaml`](spec.yaml) 自動宣告放行 Microsoft Dev Tunnels、VS Code Server 下載與 GitHub/Microsoft OAuth 驗證網域，在 Docker Sandbox Default (`balanced`) Mode 下無須手動調整網路策略即可連通。
- **全域指令 `vscode-tunnel`（不依賴工作目錄與 `Makefile`）**：進入沙盒後在任意目錄執行 `vscode-tunnel` 即可啟動 Remote Tunnel，並直接享有 `code-insiders tunnel` 原生 Singleton 防重複啟動與互動式 Attach/Detach 機制。
- **跨架構支援 (`amd64` / `arm64`)**：自動偵測目標架構，相容於 Linux x86_64 與 Apple Silicon (M 系列) Mac。
- **GitHub Actions 自動多架構發佈**：透過 Docker Buildx (`# syntax=docker/sandbox-kit:3`) 自動建置 `linux/amd64` 與 `linux/arm64` Kit OCI 映像檔並推送至 `docker.io/<你的帳號>/vscode-insiders-sandbox:latest`。

---

## 快速開始

### 方式一：直接使用已發佈至 Docker Hub (`docker.io`) 的 Kit 映像檔

當 GitHub Actions 完成發佈後，可在**任何專案目錄**下透過 `--kit` 掛載啟動 Sandbox：

```bash
# 使用 docker sandbox CLI 啟動乾淨的 shell 沙盒並掛載 Kit
docker sandbox run --kit docker.io/<你的帳號>/vscode-insiders-sandbox:latest shell .

# 或使用獨立的 sbx CLI
sbx run --kit docker.io/<你的帳號>/vscode-insiders-sandbox:latest shell .

# 亦可直接疊加於其他 AI Agent 沙盒（如 claude / codex / gemini）
sbx run --kit docker.io/<你的帳號>/vscode-insiders-sandbox:latest claude .
```

### 方式二：本地開發與啟動

宿主機 [`Makefile`](Makefile) 負責建置與啟動沙盒：

```bash
# 直接使用本地 Kit 目錄 (--kit .) 啟動 shell 沙盒
make run

# 若要指定掛載其他工作目錄或搭配特定 Agent：
make run WORKSPACE=/path/to/your/project AGENT=shell
```

若想在本地建置 Kit OCI 映像檔並匯入 `sbx` 測試：

```bash
# 1. 本地建置 Kit 映像檔 (vscode-insiders-sandbox:latest) 並匯入 sbx
make load-sbx

# 2. 使用已匯入的本地 Kit 映像檔啟動沙盒
make run-image
```

---

## 在 Sandbox 內啟動 VS Code Insiders Tunnel

進入 Sandbox 終端機後（無論位於哪一個工作目錄），直接執行全域指令：

```bash
vscode-tunnel
```

若想自訂 Tunnel 名稱，可透過環境變數 `VSCODE_TUNNEL_NAME` 或直接傳入 `--name` 參數：

```bash
# 方式 A：使用環境變數
VSCODE_TUNNEL_NAME=my-sandbox vscode-tunnel

# 方式 B：直接傳遞 CLI 參數
vscode-tunnel --name my-sandbox
```

> **防重複啟動說明**：`code-insiders tunnel` 內建 Singleton 單例鎖機制。若已在另一個終端機啟動過 Tunnel，再次執行 `vscode-tunnel` 會自動以 Client 模式附著至既有 Tunnel 行程（可按 `Ctrl+C` 安全離開觀看而不中斷背景連線）。

### 連線步驟
1. 執行 `vscode-tunnel` 後，終端機會顯示一組 GitHub / Microsoft 裝置驗證碼（Device Login Code）與登入網址。
2. 在瀏覽器完成授權後，即可透過以下任一方式連線進入 Sandbox：
   - **VS Code Insiders 桌面版**：安裝 **Remote - Tunnels** 擴充功能，點擊左下角遠端連線圖示選擇 **Connect to Tunnel...**。
   - **瀏覽器網頁版**：直接開啟 [https://insiders.vscode.dev](https://insiders.vscode.dev) 並連線至該 Tunnel。

---

## 自動發佈至 `docker.io` (GitHub Actions)

本專案已配置 [`.github/workflows/publish.yml`](.github/workflows/publish.yml)，會在推送 `v*` 版本標籤（例如 `v0.2.0`）時，使用 `docker buildx` 與 `spec.yaml` 建置 `linux/amd64,linux/arm64` 多架構 Kit OCI 映像檔並推送至 Docker Hub。

### 設定步驟
請至 GitHub Repository 的 **Settings -> Secrets and variables -> Actions** 新增以下兩個 **Repository Secrets**：

| Secret 名稱 | 說明 |
| :--- | :--- |
| `DOCKERHUB_USERNAME` | 你的 Docker Hub (`docker.io`) 帳號名稱 |
| `DOCKERHUB_TOKEN` | 你的 Docker Hub Personal Access Token（需具備 Read & Write 權限） |
