# Astra 並列ビルド実装

## 概要

`node:child_process.fork()` を使用してAstra SSGビルドを並列化。各ワーカープロセスは独自のShiki Highlighterを初期化し、親プロセスから割り当てられたページを生成する。

## アーキテクチャ

```
Main Process (astra build --parallel)
├─ Scan docs/ → pages[]
├─ Build sidebar
├─ BuilderPool 起動 (fork)
│   ├─ Worker 1 → Highlighter初期化 → ページ生成
│   ├─ Worker 2 → Highlighter初期化 → ページ生成
│   ├─ Worker 3 → Highlighter初期化 → ページ生成
│   └─ Worker 4 → Highlighter初期化 → ページ生成
├─ 全ワーカー完了待機
├─ 静的アセットコピー
└─ メタファイル生成 (sitemap, RSS, llms.txt)
```

## IPC プロトコル

```
Parent → Worker: { type: "init", configJson, pagesJson, sidebarJson, cwd }
Worker → Parent: { type: "ready" }
Parent → Worker: { type: "job", pageIndex: 0 }
Worker → Parent: { type: "done", pageIndex: 0, urlPath: "/foo/", success: true }
Parent → Worker: { type: "shutdown" }
```

## 使い方

```bash
# 直列ビルド（デフォルト）
astra build

# 並列ビルド（4ワーカー、デフォルト）
astra build --parallel
astra build -p

# ワーカー数指定
astra build -j 4
astra build -j 8
```

## ベンチマーク結果

テスト環境: 66ページ（docs/）

| モード | 時間 | CPU使用率 | 備考 |
|--------|------|-----------|------|
| 直列 | 1.8s | 129% | ベースライン |
| 並列 (4ワーカー) | 1.5s | 394% | **17%高速化** |
| 並列 (8ワーカー) | 2.8s | 366% | オーバーヘッド過多 |

### 考察

- 各ワーカーでShiki Highlighter初期化に約0.5-1秒のオーバーヘッド
- 66ページ程度では4ワーカーが最適
- ページ数が増えるほど並列化の効果が大きくなる
- 推定: 200ページ以上で2倍以上の高速化が期待できる

## 実装ファイル

### 新規作成

| ファイル | 役割 |
|---------|------|
| `src/astra/builder_pool/moon.pkg.json` | パッケージ設定 |
| `src/astra/builder_pool/types.mbt` | IPC型定義 (PoolConfig, WorkerState, JobResult, Messages) |
| `src/astra/builder_pool/serialize.mbt` | SsgConfig/PageMeta/SidebarGroup の JSON シリアライズ |
| `src/astra/builder_pool/worker.mbt` | ワーカーエントリポイント (IPC FFI + メッセージハンドラ) |
| `src/astra/builder_pool/pool.mbt` | BuilderPool 実装 (ワーカー管理 + ジョブ分配) |
| `src/astra/astra_worker/moon.pkg.json` | ワーカーメインパッケージ設定 |
| `src/astra/astra_worker/main.mbt` | ワーカーエントリポイント |
| `js/astra/src/worker.ts` | npm パッケージ用ワーカーバンドル |

### 変更

| ファイル | 変更内容 |
|---------|---------|
| `src/astra/cli/build.mbt` | `--parallel` / `-j N` フラグ追加、並列ビルドロジック |
| `src/astra/generator/static_render.mbt` | 後処理関数を pub 化 |
| `js/astra/src/cli.ts` | `globalThis.__astra_worker_script` 設定 |
| `js/astra/tsdown.config.ts` | worker.ts エントリ追加 |

## npm パッケージでの動作

npm パッケージとして配布する場合、ワーカースクリプトも `dist/worker.js` にバンドルされる。

```
@luna_ui/astra
├── bin/astra.mjs          # CLI エントリ
├── dist/
│   ├── cli.js             # CLI バンドル
│   └── worker.js          # ワーカーバンドル (180KB)
└── assets/                # 静的アセット
```

実行時のワーカーパス解決:
1. `globalThis.__astra_worker_script` が設定されていれば使用 (npm パッケージ)
2. なければ `target/js/release/build/astra/astra_worker/astra_worker.js` (開発時)

## 今後の改善案

1. **ワーカープール再利用**: dev サーバーでのインクリメンタルビルド時にワーカーを再利用
2. **Highlighter 共有**: Shiki の wasm を親プロセスで初期化し、SharedArrayBuffer で共有
3. **適応的ワーカー数**: ページ数に応じて最適なワーカー数を自動決定
