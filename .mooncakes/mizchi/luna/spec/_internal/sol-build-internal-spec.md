# Sol Build 内部仕様書

## 概要

Sol は Luna フレームワークの SSR/Hydration ビルドシステム。`sol generate` コマンドで MoonBit コードから必要なファイルを自動生成する。

## sol.config.json

```json
{
  "islands": ["app/client"],
  "routes": "app/server",
  "output": "app/__gen__",
  "client_auto_exports": true
}
```

| フィールド | 型 | デフォルト | 説明 |
|-----------|-----|----------|------|
| `islands` | `Array[String]` | `[]` | Island ディレクトリのパターン。glob 対応（例: `"app/features/*/client"`） |
| `routes` | `String` | `"app/routes"` | routes.mbt を含むディレクトリ |
| `output` | `String` | `"app/__gen__"` | 生成ファイルの出力先 |
| `client_auto_exports` | `Bool` | `true` | Island の moon.pkg.json に exports を自動追加 |

## 生成ファイル構造

```
app/
├── client/                     # Island ソースコード
│   ├── counter.mbt             # Island 実装
│   ├── __gen__.mbt             # [生成] hydrate_* 関数
│   └── moon.pkg.json           # [更新] link.js.exports 追加
├── server/
│   └── routes.mbt              # ルート定義
└── __gen__/
    ├── types/                  # [生成] Props 型定義
    │   ├── types.mbt
    │   └── moon.pkg.json
    └── server/                 # [生成] サーバーエントリ
        ├── main.mbt
        └── moon.pkg.json

.sol/{mode}/                    # [生成] JS エントリポイント
├── client/
│   ├── counter.js              # rolldown エントリ
│   └── contact_form.js
├── server/
│   └── main.js
├── manifest.json               # rolldown programmatic API 用
└── static/                     # バンドル出力先
```

## sol generate の処理フロー

### 1. Props 型の収集（ソースファイルから）

```
app/client/*.mbt → *Props 構造体を抽出
```

- `pub struct CounterProps { ... }` のようなパターンを検出
- mbti ではなくソースを直接パースして循環依存を回避

### 2. __gen__/types/ の生成

```moonbit
// __gen__/types/types.mbt
pub typealias CounterProps = @app_client.CounterProps

pub fn counter_ref() -> ComponentRef[CounterProps] {
  ComponentRef::new("counter")
}
```

### 3. moon info の実行

```bash
moon info --target js
```

- pkg.generated.mbti を生成
- pub 関数のシグネチャを取得

### 4. Island pub 関数の収集（mbti から）

```
app/client/pkg.generated.mbti → pub 関数を抽出
```

- `pub fn counter(CounterProps) -> DomNode` などを収集
- `source_pattern` で元のディレクトリを追跡

### 5. __gen__.mbt の生成

各 Island ディレクトリに hydrate_* 関数を生成：

```moonbit
// app/client/__gen__.mbt
pub fn hydrate_counter(element : @js.Any, state : @js.Any, _id : String) -> Unit {
  let jsdom_el : @js_dom.Element = element.cast()
  let json = @mbtconv.to_json(state)
  let props : CounterProps = try { @json.from_json(json) } catch { _ => return }
  let node = counter(props)
  @wc.hydrate_auto_dom(jsdom_el, node)
}
```

### 6. moon.pkg.json の更新

既存の `moon.pkg.json` に以下を追加/更新：

```json
{
  "import": [
    // 既存の import に加えて...
    { "path": "mizchi/js/core", "alias": "js" },
    { "path": "mizchi/js/mbtconv", "alias": "mbtconv" },
    { "path": "mizchi/js/browser/dom", "alias": "js_dom" },
    { "path": "mizchi/luna/platform/dom", "alias": "wc" }
  ],
  "link": {
    "js": {
      "exports": ["counter", "hydrate_counter", ...],
      "format": "esm"
    }
  }
}
```

### 7. __gen__/server/ の生成

routes.mbt をパースしてサーバーエントリポイントを生成：

```moonbit
// __gen__/server/main.mbt
fn configure_app(app : @sol.App) -> @sol.App {
  let routes = @app_server.routes()
  app.use_routes(routes)
}

fn main {
  @sol.create_app() |> configure_app |> @sol.listen(3000)
}
```

### 8. .sol/{mode}/client/ の生成

各 Island 用の JS エントリポイントを生成：

```javascript
// .sol/prod/client/counter.js
import * as mod from '../../../target/js/release/build/app/client/client.js';
export const counter = mod.counter;
export const hydrate_counter = mod.hydrate_counter;
```

### 9. manifest.json の生成

rolldown programmatic API 用のマニフェスト：

```json
{
  "islands": {
    "counter": ".sol/prod/client/counter.js",
    "contact_form": ".sol/prod/client/contact_form.js"
  },
  "server": ".sol/prod/server/main.js"
}
```

## Hydration トリガー

| トリガー | 説明 |
|---------|------|
| `load` | ページロード時即座 |
| `idle` | requestIdleCallback 時 |
| `visible` | IntersectionObserver 検知時 |
| `media` | メディアクエリマッチ時 |
| `none` | 手動トリガー |

## 複数 Islands ディレクトリ

```json
{
  "islands": ["app/client", "app/features/*/client"]
}
```

glob パターンをサポート。各サブディレクトリに対して：
- `__gen_hydrate__.mbt` を生成
- `moon.pkg.json` を更新

## 破壊的変更（v0.x → v1.0）

- `__gen__/client/` ディレクトリは生成されなくなった
- 代わりに各 Island ディレクトリ内に `__gen__.mbt` が生成される
- 既存プロジェクトは手動で `app/__gen__/client/` を削除する必要あり

## .gitignore 推奨設定

```gitignore
# Sol generated files
**/__gen__.mbt
.sol/
```

## 関連ドキュメント

- [Architecture](./architecture.md) - モジュール構成の詳細
- [Shard Architecture](../src/stella/ARCHITECTURE.md) - Island 埋め込みの仕組み
