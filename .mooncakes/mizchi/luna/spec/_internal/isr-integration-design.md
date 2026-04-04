# ISR (Incremental Static Regeneration) Integration Design

Sol と Astra の統合による ISR 実装。

## 概要

```
┌─────────────────────────────────────────────────────────────┐
│                      ビルド時 (Astra)                        │
│  ┌─────────┐    ┌──────────┐    ┌──────────────────────┐   │
│  │ Markdown│───▶│ Renderer │───▶│ Static HTML + Cache  │   │
│  └─────────┘    └──────────┘    └──────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    ランタイム (Sol)                          │
│  ┌─────────┐    ┌──────────┐    ┌──────────────────────┐   │
│  │ Request │───▶│ ISR Cache│───▶│ Serve / Regenerate   │   │
│  └─────────┘    └──────────┘    └──────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## フロー

### 1. ビルド時 (Astra)

```
1. Markdown 読み込み
2. Frontmatter から revalidate を取得
3. ページをレンダリング
4. HTML を dist/ に出力
5. ISR メタデータを _luna/isr.json に出力
```

### 2. ランタイム (Sol)

```
1. リクエスト受信
2. ISR メタ確認 (revalidate 設定があるか)
3. キャッシュ状態確認:
   - Fresh → キャッシュから即座に返す
   - Stale → キャッシュを返しつつ、バックグラウンドで再生成
   - Miss  → 再生成して返す
4. 再生成時は Astra の Renderer を使用
```

## データ構造

### Frontmatter 拡張

```yaml
---
title: My Page
revalidate: 60  # 秒単位の TTL (0 = 静的、未指定 = 静的)
---
```

### ISR メタデータ (`_luna/isr.json`)

```json
{
  "version": 1,
  "pages": {
    "/blog/post-1/": {
      "revalidate": 60,
      "renderer": "markdown",
      "source": "blog/post-1/index.md"
    },
    "/api/data/": {
      "revalidate": 10,
      "renderer": "dynamic"
    }
  }
}
```

## 実装ステップ

### Phase 1: Frontmatter 拡張

- [ ] `@astra.Frontmatter` に `revalidate: Int?` 追加
- [ ] Markdown パーサーで revalidate を解析
- [ ] ビルド時に `_luna/isr.json` を生成

### Phase 2: 共有レンダラー

- [ ] `src/core/renderer/` モジュール作成
- [ ] Markdown → HTML レンダリングを抽象化
- [ ] Astra と Sol から共通コードを呼び出し

### Phase 3: Sol ISR 統合

- [ ] Sol ランタイムで ISR メタを読み込み
- [ ] リクエストハンドラで ISR ロジック適用
- [ ] SWR (Stale-While-Revalidate) パターン実装

### Phase 4: キャッシュバックエンド

- [ ] MemoryCache (開発用) - 既存
- [ ] FileCache (Node.js 用)
- [ ] KVCache (Cloudflare Workers 用)

## API 設計

### Frontmatter

```moonbit
pub(all) struct Frontmatter {
  title : String?
  description : String?
  layout : String?
  sidebar : Bool
  noindex : Bool
  revalidate : Int?  // NEW: ISR TTL in seconds
  // ...
}
```

### ISR ミドルウェア

```moonbit
/// Sol ミドルウェアとして使用
pub fn isr_middleware[Cache : ISRCache](
  cache : Cache,
  config : ISRConfig,
) -> Middleware {
  // リクエストをインターセプト
  // キャッシュ状態に基づいて処理
}
```

### ページ再生成

```moonbit
/// ページを再生成
pub async fn regenerate_page(
  page_info : PageInfo,
  config : SsgConfig,
) -> String {
  // Markdown/HTML レンダリング
  // Shiki シンタックスハイライト
  // 完成 HTML を返す
}
```

## 設定

### sol.config.json

```json
{
  "isr": {
    "enabled": true,
    "defaultRevalidate": 60,
    "cache": "memory"  // "memory" | "file" | "kv"
  }
}
```

## 制限事項

1. **動的コンテンツ**: ISR は静的ページのみ対象。API ルートは対象外。
2. **ビルド依存**: 初回は Astra でビルドが必要。
3. **Workers 制限**: Cloudflare Workers では KV が必要。

## 将来の拡張

- On-demand revalidation API (`POST /api/revalidate?path=/blog/...`)
- タグベースの一括無効化
- Webhook 連携 (CMS 更新時に再生成)
