# next-xany: クロスターゲット対応の Any 型ライブラリ

## 背景

現在の `mizchi/js/core` はJS専用で、`extern "js"` を使用しているため WASM/Native ターゲットでビルドできない。

これにより、`mizchi/js/core` に依存するパッケージ（例: `src/server/renderer`）も JS 専用になってしまい、`moon test --target all` が通らない問題がある。

## 目標

WASM ターゲットでも動作する `@xany` ライブラリを作成する。WASM では外部からヘルパー関数を注入する前提で、プロパティアクセスや関数呼び出しに対応する。

## 設計方針

### ターゲット別実装

```
src/xany/
├── xany.mbt           # 共通インターフェース
├── xany_js.mbt        # JS実装 (extern "js")
├── xany_wasm.mbt      # WASM実装 (import from host)
└── moon.pkg.json      # targets 設定
```

### moon.pkg.json

```json
{
  "targets": {
    "xany_js.mbt": ["js"],
    "xany_wasm.mbt": ["wasm", "wasm-gc"]
  }
}
```

### 共通インターフェース (xany.mbt)

```moonbit
///| Any型のラッパー
pub type XAny

///| プロパティ取得
pub fn get(self : XAny, key : String) -> XAny

///| プロパティ設定
pub fn set(self : XAny, key : String, value : XAny) -> Unit

///| 関数呼び出し
pub fn call(self : XAny, args : Array[XAny]) -> XAny

///| メソッド呼び出し
pub fn call_method(self : XAny, method : String, args : Array[XAny]) -> XAny

///| 型変換
pub fn as_int(self : XAny) -> Int
pub fn as_string(self : XAny) -> String
pub fn as_bool(self : XAny) -> Bool
pub fn as_array(self : XAny) -> Array[XAny]

///| 値の作成
pub fn from_int(v : Int) -> XAny
pub fn from_string(v : String) -> XAny
pub fn from_bool(v : Bool) -> XAny
pub fn null() -> XAny
pub fn undefined() -> XAny
```

### JS実装 (xany_js.mbt)

```moonbit
///|
pub type XAny Any  // JS では Any をそのまま使用

///|
extern "js" fn get_internal(obj : Any, key : String) -> Any =
  #| (obj, key) => obj[key]

pub fn get(self : XAny, key : String) -> XAny {
  get_internal(self._, key)
}

// ... 他の関数も同様
```

### WASM実装 (xany_wasm.mbt)

WASM では host から注入されるヘルパー関数を使用:

```moonbit
///|
pub type XAny Int  // WASM では handle (参照ID) を使用

///|
fn xany_get(handle : Int, key_ptr : Int, key_len : Int) -> Int =
  "__xany" "get"

///|
fn xany_set(handle : Int, key_ptr : Int, key_len : Int, value : Int) -> Unit =
  "__xany" "set"

///|
fn xany_call(handle : Int, args_ptr : Int, args_len : Int) -> Int =
  "__xany" "call"

///|
pub fn get(self : XAny, key : String) -> XAny {
  // String を linear memory に書き込み、ポインタを渡す
  let (ptr, len) = string_to_wasm(key)
  xany_get(self._, ptr, len)
}
```

### Host側ヘルパー (JavaScript)

```javascript
// WASM インスタンス作成時に注入
const xanyHelpers = {
  __xany: {
    get(handle, keyPtr, keyLen) {
      const obj = handleMap.get(handle);
      const key = readString(keyPtr, keyLen);
      return createHandle(obj[key]);
    },
    set(handle, keyPtr, keyLen, valueHandle) {
      const obj = handleMap.get(handle);
      const key = readString(keyPtr, keyLen);
      obj[key] = handleMap.get(valueHandle);
    },
    call(handle, argsPtr, argsLen) {
      const fn = handleMap.get(handle);
      const args = readHandleArray(argsPtr, argsLen);
      return createHandle(fn(...args));
    }
  }
};
```

## 実装ステップ

1. [ ] `src/xany/` パッケージ作成
2. [ ] 共通インターフェース定義
3. [ ] JS実装 (`extern "js"`)
4. [ ] WASM実装 (host import)
5. [ ] Host側ヘルパーライブラリ作成
6. [ ] `src/server/renderer` を `xany` に移行
7. [ ] `moon test --target all` が通ることを確認

## 参考

- [moonbitlang/x/fs](https://github.com/moonbitlang/x/tree/main/fs) - クロスターゲット実装例
- [docs/xplat-build.md](./xplat-build.md) - MoonBit クロスターゲットビルド設定
