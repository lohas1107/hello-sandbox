# hello-sandbox (Docker Sandbox Kit v3 Monorepo)

基於 **Docker Sandbox Kit v3 (`# syntax=docker/sandbox-kit:3`)** 規範打造的多 Kit / 多 Set 沙盒儲存庫，提供：

- **基礎 Kits (`kits/*`)**：獨立發佈、可自由組合的 Mixin 與 Workload Kits（包含 VS Code Insiders Remote Tunnel Mixin 與 Google Antigravity CLI Workload）。
- **預組合 Kit Sets (`sets/*`, `kind: set`)**：在發佈期自動將 Workload 與 Mixin 以 SHA256 Digest 鎖定合併為單一映像檔，終端使用者只需指定單一 Reference 即可啟動。
- **本地環境設定檔 ([`sbxenv.yaml`](sbxenv.yaml))**：透過 `sbx env plan` / `sbx env run` 一行指令啟動宣告式開發沙盒。
- **實驗性 Kits (`experimental/*`)**：無須發佈至 Registry，可直接透過 `git+https://...#ref=main&dir=experimental/<name>` 或本地路徑掛載測試。
- **兩階段多 Repo 自動發佈 ([`.github/workflows/publish.yml`](.github/workflows/publish.yml))**：推送 `v*` 版本標籤時，自動平行建置多架構 (`linux/amd64`, `linux/arm64`) Kits 並接續合成 Sets 發佈至 Docker Hub。

---

## 儲存庫結構與發佈目標

```text
hello-sandbox/
├── kits/                                       # 獨立發佈的基礎 Kits
│   ├── vscode-insiders/                        # kind: mixin — VS Code Insiders CLI + vscode-tunnel
│   │   ├── vscode-insiders.yaml
│   │   └── vscode-insiders.dockerfile
│   └── antigravity/                            # kind: workload — Google Antigravity CLI (agy)
│       ├── antigravity.yaml
│       └── antigravity.dockerfile
├── sets/                                       # 預組合發佈的 Kit Sets (kind: set)
│   ├── shell-vscode-insiders-set/              # Shell Workload + VS Code Insiders Mixin
│   │   └── shell-vscode-insiders-set.yaml
│   └── antigravity-vscode-insiders-set/        # Antigravity Workload + VS Code Insiders Mixin
│       └── antigravity-vscode-insiders-set.yaml
├── experimental/                               # 免發佈、透過 Git URL 直接引用的實驗性 Kits
│   └── hello-banner/
│       └── hello-banner.yaml
├── sbxenv.yaml                                 # 本地宣告式沙盒環境設定檔
├── Makefile                                    # 本地驗證、建置與啟動輔助指令
└── .github/workflows/publish.yml               # 兩階段 Matrix 多架構發佈管線
```

| 類型 | 目錄位置 | `kind` | Docker Hub 映像檔 (`docker.io/<帳號>/...`) |
| :--- | :--- | :--- | :--- |
| **Mixin Kit** | [`kits/vscode-insiders`](kits/vscode-insiders/vscode-insiders.yaml) | `mixin` | `sbx-kit-vscode-insiders` |
| **Workload Kit** | [`kits/antigravity`](kits/antigravity/antigravity.yaml) | `workload` | `sbx-kit-antigravity` |
| **Kit Set** | [`sets/shell-vscode-insiders-set`](sets/shell-vscode-insiders-set/shell-vscode-insiders-set.yaml) | `set` | `sbx-kit-shell-vscode-insiders-set` |
| **Kit Set** | [`sets/antigravity-vscode-insiders-set`](sets/antigravity-vscode-insiders-set/antigravity-vscode-insiders-set.yaml) | `set` | `sbx-kit-antigravity-vscode-insiders-set` |
| **Experimental** | [`experimental/hello-banner`](experimental/hello-banner/hello-banner.yaml) | `mixin` | *(不發佈，透過 `git+https://` 直接引用)* |

---

## 快速開始

### 方式一：使用預組合 Kit Set（單一映像檔直接啟動）

當 GitHub Actions 完成發佈後，`sets/*` 已將底層 Workload 與 `sbx-kit-vscode-insiders` 合併為單一 Kit，**不需額外傳遞 `--kit`**：

```bash
# 啟動預先合成的 Shell + VS Code Insiders 沙盒
sbx run docker.io/<你的帳號>/sbx-kit-shell-vscode-insiders-set:latest .

# 啟動預先合成的 Google Antigravity (agy) + VS Code Insiders 沙盒
sbx run docker.io/<你的帳號>/sbx-kit-antigravity-vscode-insiders-set:latest .
```

### 方式二：搭配 v3 Agent Workload 自由組合 Mixin Kit

Docker 官方於 `docker.io/docker/sbx-kit-*` 提供了完整的 v3 Agent Workloads（如 `sbx-kit-shell`、`sbx-kit-claude`、`sbx-kit-codex`），可直接透過 `--kit` 疊加本專案的 Mixin：

```bash
# 1. 官方 v3 Shell Workload + VS Code Insiders Mixin
sbx run docker.io/docker/sbx-kit-shell:1.0.0 \
  --kit docker.io/<你的帳號>/sbx-kit-vscode-insiders:latest .

# 2. 官方 v3 Claude Code Workload + VS Code Insiders Mixin
sbx run docker.io/docker/sbx-kit-claude:2.1.314 \
  --kit docker.io/<你的帳號>/sbx-kit-vscode-insiders:latest .

# 3. 本專案發佈的 Antigravity Workload + 官方 GitHub CLI Mixin + VS Code Insiders Mixin
sbx run docker.io/<你的帳號>/sbx-kit-antigravity:latest \
  --kit docker.io/docker/sbx-kit-gh:latest \
  --kit docker.io/<你的帳號>/sbx-kit-vscode-insiders:latest .
```

### 方式三：使用 `sbxenv.yaml` 啟動本地宣告式開發環境

在專案根目錄下直接透過 [`sbxenv.yaml`](sbxenv.yaml) 管理沙盒（不需記憶長串參數）：

```bash
# 預覽將建立的沙盒配置與掛載
sbx env plan

# 建立（若尚未存在）並進入沙盒
sbx env run

# 移除環境沙盒
sbx env rm
```

### 方式四：透過 Git URL 直接載入實驗性 Kit（免發佈至 Registry）

放在 [`experimental/`](experimental/hello-banner/hello-banner.yaml) 的 Kit 無須推送至 Docker Hub，可直接透過 `git+https://`（或本地子目錄路徑）掛載：

```bash
# 直接從 GitHub 儲存庫子目錄拉取並由本地 sbx-kit-builder 自動建置
sbx run docker.io/docker/sbx-kit-shell:1.0.0 \
  --kit "git+https://github.com/<你的帳號>/hello-sandbox.git#ref=main&dir=experimental/hello-banner" .

# 或在本地開發時直接指向子目錄路徑（注意：不可寫成 `--kit .`，必須具備有效目錄名稱）
sbx run docker.io/docker/sbx-kit-shell:1.0.0 \
  --kit ./experimental/hello-banner .
```

### 方式五：使用 `Makefile` 本地驗證、建置與啟動

```bash
# 驗證所有本地 Kits (kits/*) 與實驗性 Kit (experimental/*)
make validate

# 本地建置所有 Kits (sbx-kit-vscode-insiders:latest, sbx-kit-antigravity:latest)
make build-all

# 使用本地 kits/vscode-insiders 疊加於官方 sbx-kit-shell:1.0.0 啟動沙盒
make run

# 使用本地 kits/antigravity workload + kits/vscode-insiders 啟動沙盒
make run-antigravity
```

---

## 在 Sandbox 內使用 `agy` 與 `vscode-tunnel`

### 1. 啟動 VS Code Insiders Remote Tunnel
進入含 `vscode-insiders` 的沙盒終端機後，在任意目錄直接執行：

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

完成終端機顯示的 GitHub / Microsoft Device Login 授權後，即可透過 **VS Code Insiders 桌面版（Remote - Tunnels 擴充功能）** 或瀏覽器開啟 [https://insiders.vscode.dev](https://insiders.vscode.dev) 連線進入沙盒。

### 2. 使用 Google Antigravity CLI (`agy`)
在 `sbx-kit-antigravity` 或 `sbx-kit-antigravity-vscode-insiders-set` 沙盒中：
- 預設 Entrypoint 會直接啟動 `agy` 互動式介面。
- 若在一般 shell 中，可隨時執行 `agy`（或 `antigravity`）、`agy -p "你的指令"`，設定檔位於 `~/.gemini/antigravity-cli/settings.json`。

---

## 自動發佈至 `docker.io`（GitHub Actions 兩階段管線）

[`.github/workflows/publish.yml`](.github/workflows/publish.yml) 會在推送 `v*` 版本標籤（例如 `v0.3.0`）或手動觸發 `workflow_dispatch` 時執行兩個階段：

1. **Stage 1 (`publish-kits`)**：平行建置 `kits/vscode-insiders` 與 `kits/antigravity` 的 `linux/amd64,linux/arm64` 多架構映像檔（含 SLSA Provenance 與 SBOM），推送至：
   - `docker.io/<帳號>/sbx-kit-vscode-insiders`
   - `docker.io/<帳號>/sbx-kit-antigravity`
2. **Stage 2 (`publish-sets`)**：待 Stage 1 完成後，自動帶入 `registry=docker.io/<帳號>` 與 `kitTag=<版本號>`，將剛發佈的 Kits 以 SHA256 Digest 鎖定合併並推送至：
   - `docker.io/<帳號>/sbx-kit-shell-vscode-insiders-set`
   - `docker.io/<帳號>/sbx-kit-antigravity-vscode-insiders-set`

### 設定步驟
請至 GitHub Repository 的 **Settings -> Secrets and variables -> Actions** 新增以下兩個 **Repository Secrets**：

| Secret 名稱 | 說明 |
| :--- | :--- |
| `DOCKERHUB_USERNAME` | 你的 Docker Hub (`docker.io`) 帳號名稱 |
| `DOCKERHUB_TOKEN` | 你的 Docker Hub Personal Access Token（需具備 Read & Write 權限） |
