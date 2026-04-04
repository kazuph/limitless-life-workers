# Route Handler Injection Design

## 課題

- ファイルスキャン (sol/routes, astra/routes) がルート定義を生成
- sol/router がハンドラをルートにアタッチする必要がある
- astra の markdown 処理を sol のルート定義に「注入」したい

## 現状

### 既存の型

```
luna/routes    : Routes (component ID strings, target-independent)
sol/routes     : SolRoutes (typed handlers: PageHandler, ApiHandler)
core/routes    : RouteManifest, RouteEntry (metadata, no handlers)
```

### 既存の変換

```
SolRoutes → RouteManifest  (sol_routes_to_manifest)
```

## 設計案: Handler Factory Pattern

### 追加する型と関数 (sol/router/manifest_adapter.mbt)

```moonbit
/// Handler factory type - creates a handler from route entry
pub type PageHandlerFactory = (@core_routes.RouteEntry) -> PageHandler?
pub type ApiHandlerFactory = (@core_routes.RouteEntry) -> ApiHandler?

/// Convert RouteManifest to SolRoutes with handler injection
pub fn manifest_to_sol_routes(
  manifest : @core_routes.RouteManifest,
  page_factory : PageHandlerFactory,
  api_factory : ApiHandlerFactory,
) -> Array[SolRoutes]
```

### 利用フロー

```
1. ファイルスキャン
   sol/routes.scan_pages_dir(fs, "docs", cwd) → RouteManifest

2. ハンドラファクトリ定義
   astra: markdown_page_factory() → PageHandlerFactory
   sol:   component_page_factory() → PageHandlerFactory

3. ルート生成
   manifest_to_sol_routes(manifest, page_factory, api_factory) → Array[SolRoutes]

4. 登録
   register_sol_routes(app, routes, config)
```

### Astra での利用例

```moonbit
/// Markdown ページ用のハンドラファクトリ
pub fn markdown_page_factory(
  renderer : MarkdownRenderer,
) -> @sol.PageHandlerFactory {
  fn(entry : @core_routes.RouteEntry) -> @sol.PageHandler? {
    match entry {
      Static(e) => {
        let source = e.source
        Some(@sol.PageHandler(async fn(props) {
          let content = read_file(source)
          let html = renderer.render(content)
          @server_dom.from_html(html)
        }))
      }
      _ => None
    }
  }
}

/// Astra の SSG ビルドでの統合
pub fn create_astra_routes(
  manifest : @core_routes.RouteManifest,
  config : AstraConfig,
) -> Array[@sol.SolRoutes] {
  let renderer = MarkdownRenderer::new(config)
  @sol.manifest_to_sol_routes(
    manifest,
    markdown_page_factory(renderer),
    default_api_factory(),
  )
}
```

### Sol での利用例

```moonbit
/// MoonBit コンポーネント用のハンドラファクトリ
pub fn component_page_factory(
  loader : ComponentLoader,
) -> PageHandlerFactory {
  fn(entry : @core_routes.RouteEntry) -> PageHandler? {
    match entry {
      Component(e) => {
        Some(PageHandler(async fn(props) {
          loader.render(e.source, props)
        }))
      }
      _ => None
    }
  }
}
```

## 利点

1. **関心の分離**
   - sol/routes: ファイルスキャン (RouteManifest 生成)
   - sol/router: ルート登録 (SolRoutes → Hono)
   - astra: コンテンツ処理 (ハンドラファクトリ提供)

2. **拡張性**
   - 新しいコンテンツタイプ (MDX, TSX等) は新しいファクトリで対応
   - 複数のファクトリを合成可能

3. **テスト容易性**
   - ファクトリは純粋関数として単体テスト可能
   - RouteManifest はモック可能

## 実装計画

### Phase 1: 基本実装
1. `manifest_to_sol_routes` を sol/router/manifest_adapter.mbt に追加
2. テスト追加

### Phase 2: Astra 統合
1. astra にファクトリ関数を追加
2. 既存の SSG ビルドをファクトリベースに移行

### Phase 3: 複合ファクトリ
1. 複数のファクトリを合成するユーティリティ
2. fallback チェーン対応
