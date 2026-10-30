# hello-sandbox (VS Code Insiders Docker Sandbox)

基於官方 `docker/sandbox-templates:shell` 的輕量級 **Docker Sandbox 自定義範本（Custom Template）**。預設**不安裝任何 AI Agent**，僅預載支援多架構（`linux/amd64`、`linux/arm64`）的 **VS Code Insiders CLI (`code-insiders`)** 與 `make`。

## 專案特色

- **乾淨無預設 Agent**：以 `docker/sandbox-templates:shell` 為基底，不含任何預設 AI Agent 與多餘依賴。
- **跨架構支援 (`amd64` / `arm64`)**：自動偵測目標架構，安裝對應的官方 `code-insiders` CLI，相容於 Linux x86_64 與 Apple Silicon (M 系列) Mac。
- **按需啟動 Tunnel (`make tunnel`)**：進入 Sandbox 時保持乾淨的 `bash` Shell，需要連線時執行 `make tunnel` 即可啟動 VS Code Insiders Remote Tunnel。
- **GitHub Actions 自動多架構發佈**：透過 Docker Buildx 自動建置 `linux/amd64` 與 `linux/arm64` 映像檔並推送至 `docker.io/<你的帳號>/vscode-insiders-sandbox:latest`。

---

## 快速開始

### 方式一：直接使用已發佈至 Docker Hub (`docker.io`) 的映像檔

當 GitHub Actions 完成發佈後，可直接指定遠端映像檔啟動 Sandbox：

```bash
# 使用 docker sandbox CLI
docker sandbox run --template docker.io/<你的帳號>/vscode-insiders-sandbox:latest shell .

# 或使用獨立的 sbx CLI
sbx run -t docker.io/<你的帳號>/vscode-insiders-sandbox:latest shell .
```

### 方式二：本地建置與啟動

```bash
# 1. 本地建置映像檔 (vscode-insiders-sandbox:latest)
make build

# (若使用獨立的 sbx CLI，需先將本地映像檔匯入 sbx image store)
make load-sbx

# 2. 啟動並進入 Sandbox
make run
```

---

## 在 Sandbox 內啟動 VS Code Insiders Tunnel

進入 Sandbox 的 `/home/agent/workspace` 終端機後，執行：

```bash
make tunnel
```

若想自訂 Tunnel 名稱，可傳入 `VSCODE_TUNNEL_NAME`：

```bash
make tunnel VSCODE_TUNNEL_NAME=my-sandbox
```

### 連線步驟
1. 執行 `make tunnel` 後，終端機會顯示一組 GitHub / Microsoft 裝置驗證碼（Device Login Code）與登入網址。
2. 在瀏覽器完成授權後，即可透過以下任一方式連線進入 Sandbox：
   - **VS Code Insiders 桌面版**：安裝 **Remote - Tunnels** 擴充功能，點擊左下角遠端連線圖示選擇 **Connect to Tunnel...**。
   - **瀏覽器網頁版**：直接開啟 [https://insiders.vscode.dev](https://insiders.vscode.dev) 並連線至該 Tunnel。

---

## 自動發佈至 `docker.io` (GitHub Actions)

本專案已配置 [`.github/workflows/publish.yml`](.github/workflows/publish.yml)，會在推送 `v*` 版本標籤（例如 `v1.0.0`）時，使用 `docker buildx` 建置 `linux/amd64,linux/arm64` 多架構映像檔並推送至 Docker Hub。

### 設定步驟
請至 GitHub Repository 的 **Settings -> Secrets and variables -> Actions** 新增以下兩個 **Repository Secrets**：

| Secret 名稱 | 說明 |
| :--- | :--- |
| `DOCKERHUB_USERNAME` | 你的 Docker Hub (`docker.io`) 帳號名稱 |
| `DOCKERHUB_TOKEN` | 你的 Docker Hub Personal Access Token（需具備 Read & Write 權限） |
