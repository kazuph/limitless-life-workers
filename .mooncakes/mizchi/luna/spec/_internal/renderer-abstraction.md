# Renderer Abstraction Design

## 概要

Astro の Integration API を参考に、Luna を汎用的なレンダリングフレームワークに拡張する設計。

## Astro の設計からの学び

### Astro Integration API

Astro は以下の概念で構成される:

1. **Renderer** - フレームワーク（React, Vue, Svelte）のレンダリング実装
   - `serverEntrypoint`: SSR 時にコンポーネントを静的 HTML に変換
   - `clientEntrypoint`: クライアントでハイドレーション/レンダリング

2. **Adapter** - デプロイ先（Vercel, Cloudflare）の差異を吸収
   - SSR manifest の生成
   - ホスト固有の API ラッパー

3. **Client Directives** - ハイドレーションタイミング制御
   - `client:load` - 即座にハイドレート
   - `client:idle` - ブラウザアイドル時
   - `client:visible` - ビューポートに入った時
   - `client:only` - SSR なし、クライアントのみ

4. **Islands** - 独立したインタラクティブ領域
   - Client Islands: クライアントでハイドレート
   - Server Islands: サーバーで遅延レンダリング

## Luna の設計目標

### 1. 抽象レンダーツリー (Abstract Render Tree)

フレームワーク非依存のノード構造:

```moonbit
/// フレームワーク非依存の抽象ノード
pub(all) enum AbstractNode {
  Element(
    tag~ : String,
    attrs~ : Array[(String, AttrValue)],
    children~ : Array[AbstractNode]
  )
  Text(String)
  Fragment(Array[AbstractNode])
  Component(
    name~ : String,
    props~ : Json,
    render_mode~ : RenderMode,
    children~ : Array[AbstractNode]
  )
  Slot(name~ : String, fallback~ : Array[AbstractNode])
}

/// 属性値の型
pub(all) enum AttrValue {
  StringValue(String)
  BoolValue(Bool)
  NumberValue(Double)
  EventHandler(String)  // クライアントのみ
  JsonValue(Json)
}
```

### 2. レンダリングモード

```moonbit
/// レンダリングモードの定義
pub(all) enum RenderMode {
  /// サーバーのみ、クライアント JS なし
  SSROnly

  /// サーバーで HTML 生成後、クライアントでハイドレート
  Hydration(HydrationTrigger)

  /// クライアントのみでレンダリング（プレースホルダー表示）
  ClientOnly

  /// サーバーで遅延レンダリング（Server Islands）
  ServerDefer
}

/// ハイドレーションのトリガー条件
pub(all) enum HydrationTrigger {
  Load      // 即座に
  Idle      // requestIdleCallback
  Visible   // IntersectionObserver
  Media(String)  // メディアクエリ一致時
}
```

### 3. Renderer Trait

各フレームワークが実装するインターフェース:

```moonbit
/// サーバーサイドレンダラー
pub(open) trait ServerRenderer {
  /// 抽象ノードを HTML 文字列に変換
  render_to_string(Self, AbstractNode) -> String

  /// ハイドレーション用のマーカーを含む HTML を生成
  render_with_hydration_markers(Self, AbstractNode) -> String

  /// コンポーネントのメタデータを取得
  get_component_metadata(Self, String) -> ComponentMeta?
}

/// クライアントサイドレンダラー
pub(open) trait ClientRenderer {
  /// DOM 要素にマウント
  mount(Self, AbstractNode, target~ : DomElement) -> Unit

  /// 既存の HTML をハイドレート
  hydrate(Self, AbstractNode, target~ : DomElement) -> Unit

  /// 差分更新
  update(Self, old~ : AbstractNode, new~ : AbstractNode) -> Unit
}

/// コンポーネントメタデータ
pub(all) struct ComponentMeta {
  name : String
  props_schema : Json?
  has_client_code : Bool
  dependencies : Array[String]
}
```

### 4. Renderer 実装例

```moonbit
// Luna Native Renderer
pub struct LunaRenderer {}

impl ServerRenderer for LunaRenderer {
  fn render_to_string(self : LunaRenderer, node : AbstractNode) -> String {
    // Luna の VNode に変換して server_dom でレンダリング
    let vnode = abstract_to_luna_vnode(node)
    @server_dom.render_to_string(vnode)
  }

  fn render_with_hydration_markers(self : LunaRenderer, node : AbstractNode) -> String {
    let vnode = abstract_to_luna_vnode(node)
    @server_dom.render_with_markers(vnode)
  }
}

// React Renderer (外部実装)
// preact, solid なども同様のパターン
```

### 5. 統合レジストリ

```moonbit
/// レンダラーの登録と管理
pub struct RendererRegistry {
  renderers : Map[String, RendererConfig]
}

pub struct RendererConfig {
  name : String
  /// サーバーエントリポイント（MoonBit モジュールパス）
  server_entrypoint : String
  /// クライアントエントリポイント（JS バンドルパス）
  client_entrypoint : String
  /// サポートするファイル拡張子
  extensions : Array[String]
  /// サポートする機能
  features : RendererFeatures
}

pub struct RendererFeatures {
  supports_ssr : Bool
  supports_hydration : Bool
  supports_streaming : Bool
  supports_server_islands : Bool
}
```

## ユニットテスト戦略

### 1. 抽象ノードのテスト

```moonbit
test "abstract node structure" {
  let node = AbstractNode::Element(
    tag="div",
    attrs=[("class", StringValue("container"))],
    children=[
      AbstractNode::Text("Hello"),
      AbstractNode::Component(
        name="Counter",
        props=Json::Object({}),
        render_mode=Hydration(Load),
        children=[]
      )
    ]
  )

  // 構造のバリデーション
  assert_eq!(count_components(node), 1)
  assert_eq!(get_render_modes(node), [Hydration(Load)])
}
```

### 2. レンダラーの出力テスト

```moonbit
test "luna renderer output" {
  let renderer = LunaRenderer::new()
  let node = AbstractNode::Element(
    tag="button",
    attrs=[("onclick", EventHandler("handleClick"))],
    children=[AbstractNode::Text("Click me")]
  )

  // SSR 出力
  let html = renderer.render_to_string(node)
  assert!(html.contains("<button"))
  assert!(html.contains("Click me"))

  // ハイドレーションマーカー
  let hydrated = renderer.render_with_hydration_markers(node)
  assert!(hydrated.contains("data-hk="))
}
```

### 3. モード変換のテスト

```moonbit
test "render mode affects output" {
  let component = AbstractNode::Component(
    name="Interactive",
    props=Json::Object({}),
    render_mode=ClientOnly,
    children=[]
  )

  let renderer = LunaRenderer::new()
  let html = renderer.render_to_string(component)

  // ClientOnly はプレースホルダーのみ
  assert!(html.contains("data-island"))
  assert!(!html.contains("actual content"))
}
```

## ファイル構成案

```
src/
├── core/
│   └── render/
│       ├── abstract_node.mbt     # AbstractNode 定義
│       ├── render_mode.mbt       # RenderMode 定義
│       ├── traits.mbt            # ServerRenderer, ClientRenderer traits
│       └── registry.mbt          # RendererRegistry
├── renderers/
│   ├── luna/                     # Luna native renderer
│   │   ├── server.mbt
│   │   └── client.mbt
│   └── react/                    # React renderer (future)
│       ├── server.mbt
│       └── client.mbt
└── integration/
    └── astro_compat.mbt          # Astro 互換レイヤー (optional)
```

## マイグレーションパス

### Phase 1: 抽象ノード導入
1. `AbstractNode` 型を定義
2. 既存の `VNode` との変換関数を実装
3. 既存コードへの影響なし

### Phase 2: Renderer Trait
1. `ServerRenderer`, `ClientRenderer` trait を定義
2. Luna 実装を trait ベースに移行
3. ユニットテスト追加

### Phase 3: 外部レンダラー対応
1. React renderer の実装
2. Preact renderer の実装
3. RendererRegistry による動的選択

### Phase 4: 型安全なモード指定
1. コンパイル時のモード検証
2. 不正な組み合わせのエラー検出
3. IDE サポート強化

## 現在の Luna Node 構造との対応

### 現在の Luna Node

```moonbit
pub enum Node[E] {
  Element(VElement[E])
  Text(String)
  DynamicText(() -> String)
  Fragment(Array[Node[E]])
  Show(condition~ : () -> Bool, child~ : () -> Node[E])
  For(render~ : () -> Array[Node[E]])
  Component(render~ : () -> Node[E])
  Island(VIsland[E])           // luna:* style hydration
  WcIsland(VWcIsland[E])       // Web Components based
  Async(VAsync[E])
  ErrorBoundary(VErrorBoundary[E])
  Switch(VSwitch[E])
  InternalRef(VInternalRef[E])
  RawHtml(String)
}
```

### AbstractNode への変換

| Luna Node | AbstractNode | RenderMode |
|-----------|--------------|------------|
| `Element` | `Element` | - |
| `Text` | `Text` | - |
| `DynamicText` | `Text` (evaluated) | - |
| `Fragment` | `Fragment` | - |
| `Show/For/Switch` | (evaluated to children) | - |
| `Component` | `Component` | SSROnly |
| `Island` | `Component` | Hydration(trigger) |
| `WcIsland` | `Component` | Hydration(trigger) + WebComponent |
| `InternalRef` | `Component` | Hydration(trigger) |
| `Async` | `Component` | ServerDefer |

### 変換関数

```moonbit
/// Luna Node を AbstractNode に変換
pub fn luna_to_abstract[E](node : @luna.Node[E]) -> AbstractNode {
  match node {
    Element(el) => AbstractNode::Element(
      tag=el.tag,
      attrs=convert_attrs(el.attrs),
      children=el.children.map(luna_to_abstract)
    )
    Text(s) => AbstractNode::Text(s)
    DynamicText(f) => AbstractNode::Text(f())
    Fragment(children) => AbstractNode::Fragment(
      children.map(luna_to_abstract)
    )
    Island(island) => AbstractNode::Component(
      name=island.name,
      props=island.state,
      render_mode=Hydration(convert_trigger(island.trigger)),
      children=[luna_to_abstract(island.children)]
    )
    // ... other cases
  }
}
```

## 実装ロードマップ

### Step 1: AbstractNode 型定義 (src/core/render/)

```
src/core/render/
├── moon.pkg.json
├── abstract_node.mbt    # AbstractNode enum
├── render_mode.mbt      # RenderMode enum
├── attr_value.mbt       # AttrValue enum
└── abstract_node_test.mbt
```

### Step 2: Renderer Trait 定義

```
src/core/render/
├── traits.mbt           # ServerRenderer, ClientRenderer
├── component_meta.mbt   # ComponentMeta struct
└── registry.mbt         # RendererRegistry
```

### Step 3: Luna Renderer 実装

```
src/renderers/luna/
├── moon.pkg.json
├── server.mbt           # impl ServerRenderer for LunaRenderer
├── client.mbt           # impl ClientRenderer for LunaRenderer
├── convert.mbt          # Node[E] <-> AbstractNode
└── server_test.mbt
```

### Step 4: React/Preact Renderer (外部)

```
src/renderers/react/
├── moon.pkg.json
├── server.mbt           # React.renderToString wrapper
├── client.mbt           # React.hydrateRoot wrapper
└── bindings.mbt         # FFI bindings
```

## 型安全なモード指定

### コンパイル時検証

```moonbit
/// SSR専用コンポーネントを表すファントム型
pub struct SSROnly {}

/// ハイドレーション対応コンポーネント
pub struct Hydratable {}

/// クライアントオンリーコンポーネント
pub struct ClientOnlyMarker {}

/// 型安全なコンポーネント定義
pub fn define_component[Mode](
  name : String,
  render : () -> AbstractNode
) -> TypedComponent[Mode] {
  // Mode によって生成されるコードが変わる
}

// 使用例
let ssr_only = define_component[SSROnly]("Header", header_render)
let interactive = define_component[Hydratable]("Counter", counter_render)

// コンパイルエラー: SSROnly を Island に埋め込もうとした
// Island::new(ssr_only)  // Error!
```

### ビルド時最適化

```moonbit
/// ビルド時に RenderMode を解析して最適化
pub fn optimize_render_tree(root : AbstractNode) -> OptimizedTree {
  // 1. SSROnly ノードをインライン化
  // 2. ClientOnly ノードのプレースホルダー生成
  // 3. Hydration 境界の自動検出
  // 4. 不要な JavaScript の除去
}
```

## 参考リンク

- [Astro Integration API](https://docs.astro.build/en/reference/integrations-reference/)
- [Astro Adapter API](https://docs.astro.build/en/reference/adapter-reference/)
- [Astro Islands Architecture](https://docs.astro.build/en/concepts/islands/)
