# Pagefind テスト

静的サイト検索ライブラリ [Pagefind](https://pagefind.app/) の検証用プロジェクト。

## セットアップ

```bash
cd experiments/pagefind_test
pnpm install
```

## 使い方

```bash
# インデックス作成 & 開発サーバー起動
pnpm serve

# http://localhost:1414 でアクセス
```

## ファイル構成

```
dist/
├── index.html      # プリビルトUI使用
├── custom-ui.html  # カスタムUI（JavaScript API使用）
├── page1.html      # Luna説明ページ
├── page2.html      # Sol説明ページ
├── page3.html      # Astra説明ページ
└── _pagefind/      # 生成されるインデックス
```

## ポイント

### data-pagefind-body

検索対象のコンテンツを `data-pagefind-body` 属性でマークする:

```html
<main data-pagefind-body>
  <!-- この中のテキストがインデックスされる -->
</main>
```

### プリビルトUI

```html
<link href="/pagefind/pagefind-ui.css" rel="stylesheet">
<script src="/pagefind/pagefind-ui.js"></script>
<div id="search"></div>
<script>
  new PagefindUI({ element: "#search" });
</script>
```

### カスタムUI (JavaScript API)

```javascript
const pagefind = await import('/pagefind/pagefind.js');
const search = await pagefind.search("クエリ");

for (const result of search.results) {
  const data = await result.data();
  console.log(data.url, data.meta.title, data.excerpt);
}
```

## バンドルサイズ

| ファイル | サイズ (gzip) |
|---------|--------------|
| pagefind.js | ~7KB |
| pagefind.wasm | ~70KB |
| pagefind-ui.js + css | ~15KB |

WASMとインデックスは検索時に遅延読み込みされる。
