# MoonBit Virtual Package

Virtual Packageは、インターフェースと実装を分離し、複数の実装を切り替え可能にするMoonBitの機能。

## 概要

```
┌─────────────────┐     ┌──────────────────┐
│  virtual pkg    │     │  consumer pkg    │
│  (interface)    │◄────│  (uses interface)│
│  *.mbti         │     │                  │
└────────┬────────┘     └──────────────────┘
         │
    implements
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌────────┐
│ impl A │ │ impl B │
│(default)│ │(custom)│
└────────┘ └────────┘
```

## 設定方法

### 1. Virtual Package の定義

インターフェースを定義するパッケージ。`.mbti`ファイルでAPIを宣言する。

**moon.pkg.json:**
```json
{
  "virtual": {
    "has-default": true
  }
}
```

- `has-default: true` - このパッケージ内の`.mbt`ファイルがデフォルト実装として使用される
- `has-default: false` - デフォルト実装なし、必ず`overrides`で実装を指定する必要がある

**interface.mbti:**
```moonbit
// 公開するAPIを宣言
fn serve(port : Int) -> Unit
fn create_app() -> App
```

### 2. 実装パッケージの定義

Virtual Packageのインターフェースを実装するパッケージ。

**moon.pkg.json:**
```json
{
  "implement": "username/project/virtual_pkg"
}
```

実装パッケージは`.mbti`で宣言されたすべての関数を実装する必要がある。

### 3. 実装の切り替え

使用側のパッケージで`overrides`を指定して実装を切り替える。

**moon.pkg.json:**
```json
{
  "is-main": true,
  "import": [
    "username/project/lib"
  ],
  "overrides": [
    "username/project/impl_b"
  ]
}
```

`overrides`を指定しない場合、デフォルト実装が使用される。

## 実例: moonbitlang/core/abort

MoonBitコアライブラリの`abort`パッケージは virtual package として実装されている。

```bash
# カスタム実装を追加
moon add moonbitlang/dummy_abort
```

**moon.pkg.json:**
```json
{
  "overrides": [
    "moonbitlang/dummy_abort/abort_show_msg"
  ]
}
```

これにより、`abort()`呼び出し時の動作をカスタマイズできる。

## Luna/Solでの活用案

### サーバー実装の切り替え

現在のSolはHono（Node.js）に依存しているが、virtual packageを使用することで異なるサーバー実装を切り替え可能にできる。

**構成案:**
```
src/platform/
├── server/                    # Virtual Package (interface)
│   ├── moon.pkg.json          # "virtual": { "has-default": true }
│   ├── server.mbti            # interface定義
│   └── server.mbt             # デフォルト実装 (Hono)
├── server_hono/               # Hono実装
│   ├── moon.pkg.json          # "implement": "mizchi/luna/platform/server"
│   └── hono.mbt
└── server_async/              # moonbitlang/async実装
    ├── moon.pkg.json          # "implement": "mizchi/luna/platform/server"
    └── async_server.mbt
```

**server.mbti (インターフェース):**
```moonbit
// サーバーの基本インターフェース
pub type App
pub type Context

pub fn create_app() -> App
pub fn serve(app : App, port : Int) -> Unit
pub fn get(app : App, path : String, handler : (Context) -> Response) -> App
pub fn post(app : App, path : String, handler : (Context) -> Response) -> App
```

**使用側:**
```json
{
  "import": ["mizchi/luna/sol"],
  "overrides": ["mizchi/luna/platform/server_async"]
}
```

### 利点

1. **プラットフォーム対応**: Hono/Node.js、moonbitlang/async、Cloudflare Workers等を切り替え可能
2. **テスト容易性**: モック実装を注入できる
3. **段階的移行**: デフォルトをHonoに保ちながら、新実装を試験的に導入できる

## ターゲット別ファイル分岐 (targets)

`moonbitlang/x/fs` のパターン。同一パッケージ内でファイルごとにターゲットを指定できる。

```json
{
  "targets": {
    "fs_wasm.mbt": ["wasm", "wasm-gc"],
    "fs_js.mbt": ["js"],
    "fs_native.mbt": ["native", "llvm"]
  }
}
```

これにより：
- `moon check --target js` → `fs_js.mbt` のみビルド
- `moon check --target native` → `fs_native.mbt` のみビルド
- 共通コードは `targets` に含めないファイルに配置

## 実装例: HelloWorld サーバー

`src/platform/experimental_server/` に実験的な実装あり。

```
src/platform/experimental_server/
├── server/           # Virtual Package (interface)
│   ├── moon.pkg.json
│   └── pkg.mbti
└── impl/             # 実装 (targets で分岐)
    ├── moon.pkg.json
    ├── server_js.mbt     # JS/Hono 実装
    └── server_native.mbt # Native/async 実装
```

### Virtual Package (インターフェース)

**`server/moon.pkg.json`:**
```json
{
  "virtual": {
    "has-default": false
  }
}
```

**`server/pkg.mbti`:**
```moonbit
package "mizchi/luna/platform/experimental_server/server"

// Values
fn serve(Int) -> Unit
```

### 実装パッケージ (targets で分岐)

**`impl/moon.pkg.json`:**
```json
{
  "import": [
    { "path": "mizchi/js/core", "alias": "js" },
    { "path": "moonbitlang/async", "alias": "mbasync" },
    { "path": "moonbitlang/async/http", "alias": "http" },
    { "path": "moonbitlang/async/socket", "alias": "socket" }
  ],
  "targets": {
    "server_js.mbt": ["js"],
    "server_native.mbt": ["native"]
  },
  "implement": "mizchi/luna/platform/experimental_server/server"
}
```

**`impl/server_js.mbt`** (Hono/JS):
```moonbit
extern "js" fn ffi_new_hono() -> @js.Any =
  #|() => {
  #|  const { Hono } = require('hono');
  #|  return new Hono();
  #|}

extern "js" fn ffi_hono_get(app : @js.Any, path : String, handler : (@js.Any) -> @js.Any) -> Unit =
  #|(app, path, handler) => { app.get(path, (c) => handler(c)); }

extern "js" fn ffi_hono_serve(app : @js.Any, port : Int) -> Unit =
  #|(app, port) => {
  #|  import('@hono/node-server').then(({ serve }) => {
  #|    serve({ fetch: app.fetch, port });
  #|  });
  #|}

extern "js" fn ffi_ctx_text(c : @js.Any, text : String) -> @js.Any =
  #|(c, text) => c.text(text)

pub fn serve(port : Int) -> Unit {
  let app = ffi_new_hono()
  ffi_hono_get(app, "/", fn(c) { ffi_ctx_text(c, "Hello, World!") })
  ffi_hono_serve(app, port)
}
```

**`impl/server_native.mbt`** (moonbitlang/async):
```moonbit
pub fn serve(port : Int) -> Unit {
  @mbasync.run_async_main(async fn() { serve_async(port) })
}

async fn serve_async(port : Int) -> Unit {
  let addr = @socket.Addr::new(0U, port)
  let server = @http.Server::new(addr)
  server.run_forever(async fn(request, _reader, conn) {
    conn.send_response(200, "OK", extra_headers={"Content-Type": "text/plain"})
    conn.write("Hello, World!")
    conn.end_response()
  })
}
```

## 注意点

- `.mbti`で宣言されたすべての関数を実装しなければコンパイルエラー
- 現在は実験的機能（experimental）
- 複数の`overrides`は依存関係の順序に注意
- **ターゲット制限**: `supported-targets`で制限しても、他ターゲットのチェック時にエラーになる場合がある

## 参考リンク

- [Introducing virtual package in MoonBit](https://www.moonbitlang.com/blog/virtual-package)
- [Package Configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)
