# コードハイライティング実装調査

## 概要

Shiki/TextMate ベースのコードハイライティングを MoonBit で実装する可能性を調査。

## Shiki アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│  textmate-grammars-themes                                    │
│  ├─ VSCode等から grammar/theme を収集                        │
│  ├─ JSON形式に正規化                                         │
│  └─ 毎日自動更新・npm配布                                     │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  Shiki                                                       │
│  ├─ vscode-textmate (トークナイザー本体)                     │
│  ├─ engine-oniguruma (WASM正規表現エンジン)                  │
│  └─ engine-javascript (oniguruma-to-es経由)                  │
└─────────────────────────────────────────────────────────────┘
```

### 主要コンポーネント

| コンポーネント | 役割 | リポジトリ |
|--------------|------|-----------|
| textmate-grammars-themes | grammar/theme の収集・正規化 | [shikijs/textmate-grammars-themes](https://github.com/shikijs/textmate-grammars-themes) |
| vscode-textmate | TextMate grammar インタープリタ | [microsoft/vscode-textmate](https://github.com/microsoft/vscode-textmate) |
| engine-oniguruma | Oniguruma WASM ラッパー | shikijs/shiki |
| oniguruma-to-es | Oniguruma→JS変換 | [slevithan/oniguruma-to-es](https://github.com/slevithan/oniguruma-to-es) |

## TextMate Grammar の仕組み

### 基本構造

```json
{
  "name": "JavaScript",
  "scopeName": "source.js",
  "patterns": [
    { "include": "#comments" },
    { "include": "#strings" }
  ],
  "repository": {
    "comments": {
      "match": "//.*$",
      "name": "comment.line.double-slash.js"
    },
    "strings": {
      "begin": "\"",
      "end": "\"",
      "name": "string.quoted.double.js",
      "patterns": [
        { "match": "\\\\.", "name": "constant.character.escape.js" }
      ]
    }
  }
}
```

### パターンタイプ

1. **match**: 単一行パターン
   ```json
   { "match": "\\b(if|else|while)\\b", "name": "keyword.control" }
   ```

2. **begin/end**: 複数行にまたがる構造
   ```json
   {
     "begin": "/\\*",
     "end": "\\*/",
     "name": "comment.block"
   }
   ```

3. **include**: 他のパターンを参照
   ```json
   { "include": "#strings" }
   { "include": "source.css" }
   ```

### トークナイズアルゴリズム

```
入力: 行のリスト、grammar、初期状態
出力: トークンリスト

for each line:
    tokens = []
    position = 0

    while position < line.length:
        best_match = None

        # 現在のルールスタックの全パターンを試行
        for pattern in current_rules:
            match = pattern.match(line, position)
            if match and (best_match is None or match.start < best_match.start):
                best_match = match

        if best_match:
            # マッチ前のテキストをトークン化
            if best_match.start > position:
                tokens.append(Token(position, best_match.start, current_scope))

            # マッチ部分を処理
            if pattern.type == 'begin':
                push_state(pattern.end, pattern.patterns)
            elif pattern.type == 'end':
                pop_state()

            tokens.append(Token(best_match, pattern.scope))
            position = best_match.end
        else:
            # マッチなし - 行末まで現在のスコープ
            tokens.append(Token(position, line.length, current_scope))
            break

    yield tokens
```

### 重要な制約

- **行単位処理**: 正規表現は1行に対してのみマッチ
- **状態管理**: `ruleStack` で行間のコンテキストを維持
- **スコープネスト**: トークンは親スコープのリストを持つ

## 正規表現エンジンの比較

### Oniguruma vs JavaScript RegExp

| 機能 | Oniguruma | JS RegExp | 備考 |
|------|-----------|-----------|------|
| 基本パターン | ✅ | ✅ | |
| 先読み `(?=)` `(?!)` | ✅ | ✅ | |
| 後読み `(?<=)` `(?<!)` | ✅ | ✅ (ES2018+) | |
| 名前付きキャプチャ | ✅ | ✅ (ES2018+) | |
| Unicode プロパティ | ✅ | ✅ (ES2018+) | |
| 原子グループ `(?>)` | ✅ | ❌ | エミュレーション可 |
| 条件分岐 `(?(1)...)` | ✅ | ❌ | |
| `\G` アンカー | ✅ | ❌ | 前回マッチ位置 |
| `\K` (マッチリセット) | ✅ | ❌ | |

### エンジン選択肢

| エンジン | サイズ | 互換性 | 速度 |
|---------|--------|--------|------|
| Oniguruma WASM | ~1.3MB | 100% | 高速 |
| oniguruma-to-es | ~3KB | 99.99% | より高速 |

## MoonBit regex の現状

### サポート機能

```moonbit
// 基本
let re = @regex.compile("a(bc|de)f")

// 文字クラス
let re = @regex.compile("\\d+\\.\\d{2}")

// 名前付きキャプチャ
let re = @regex.compile("(?<year>\\d{4})-(?<month>\\d{2})")

// Unicode プロパティ
let re = @regex.compile("\\p{Letter}+")
```

### TextMate に必要だが未実装の機能

| 機能 | 用途 | 重要度 |
|------|------|--------|
| `\G` アンカー | 連続マッチ | **必須** |
| 先読み `(?=)` `(?!)` | 境界検出 | 高 |
| 後読み `(?<=)` `(?<!)` | 境界検出 | 高 |
| バックリファレンス | end での begin 参照 | 高 |
| 原子グループ `(?>)` | バックトラック制御 | 中 |

### `\G` の重要性

TextMate grammar では `\G` が頻繁に使われる：

```json
{
  "begin": "\\{",
  "end": "\\}",
  "patterns": [
    {
      "match": "\\G\\s*",
      "name": "meta.brace.open"
    }
  ]
}
```

`\G` は「前回のマッチが終わった位置」を意味し、連続トークナイズに必須。

## 実装アプローチ

### 選択肢A: WASM FFI (推奨・初期実装)

```
MoonBit (API) → JS FFI → vscode-textmate + oniguruma-to-es
```

**メリット**:
- 開発コスト最小
- 100% TextMate 互換
- 既存 grammar/theme をそのまま利用

**デメリット**:
- JS 環境依存
- WASM-GC ネイティブではない

### 選択肢B: トークナイザーを MoonBit で実装

```moonbit
pub(all) struct Grammar {
  scope_name : String
  patterns : Array[Pattern]
  repository : Map[String, Pattern]
}

pub(all) enum Pattern {
  Match(regex~, name~, captures~)
  BeginEnd(begin~, end~, name~, patterns~, content_name~)
  Include(ref~)
}

pub(all) struct RuleStack {
  rules : Array[Rule]
  // 状態管理
}

pub fn tokenize_line(
  grammar : Grammar,
  line : String,
  state : RuleStack,
  regex_engine : RegexEngine  // 外部エンジン
) -> (Array[Token], RuleStack)
```

**メリット**:
- MoonBit ネイティブ
- 正規表現エンジンを差し替え可能

**デメリット**:
- 開発コスト中
- 正規表現エンジンの問題は残る

### 選択肢C: MoonBit regex の拡張

必要な機能を追加実装：

1. `\G` アンカー（位置パラメータで代替可能）
2. 先読み/後読み
3. バックリファレンス

**メリット**:
- 完全な MoonBit ネイティブ
- WASM-GC で高速

**デメリット**:
- 開発コスト高
- 全機能の実装は困難

### 選択肢D: tree-sitter アプローチ

TextMate ではなく tree-sitter パーサーを使用。

**MoonBit バインディング**: [tonyfettes/tree_sitter](https://mooncakes.io/docs/tonyfettes/tree_sitter)

```moonbit
let moonbit = @tree_sitter_moonbit.language()
let parser = @tree_sitter.Parser::new()
parser.set_language(moonbit)
let tree = parser.parse_string(source_code)
let root = tree.root_node()
```

**メリット**:
- 正確な構文木（AST）を生成
- インクリメンタルパース対応
- MoonBit バインディングが既に存在
- 多くの言語の grammar が利用可能

**デメリット**:
- TextMate theme との互換性なし（スコープ体系が異なる）
- C ライブラリへの依存（WASM 経由）
- grammar ファイルが大きい

### 選択肢E: Lezer アプローチ

CodeMirror 6 で使われる JavaScript 製パーサーシステム。

**特徴**:
- LR パーサー（GLR オプション）
- インクリメンタルパース対応
- エラー回復機能
- コンパクトな出力サイズ

```javascript
// Lezer grammar 例
@top Program { expression* }
expression { Number | BinaryExpression }
BinaryExpression { expression ("+" | "-") expression }
@tokens { Number { @digit+ } }
```

**メリット**:
- 純粋 JavaScript（WASM 不要）
- コンパクトなパーサーテーブル
- メモリ効率が良い（64bit/ノード）
- Web 向けに最適化

**デメリット**:
- TextMate theme との互換性なし
- grammar エコシステムが小さい（~15言語）
- MoonBit バインディングなし（要実装）

### 選択肢比較表

| アプローチ | 開発コスト | 互換性 | パフォーマンス | エコシステム |
|-----------|-----------|--------|--------------|-------------|
| A) JS FFI (shiki) | 低 | TextMate 100% | 中 | 豊富 |
| B) MoonBit トークナイザー | 中 | TextMate 100% | 高 | 豊富 |
| C) MoonBit regex 拡張 | 高 | TextMate 80-90% | 高 | 豊富 |
| D) tree-sitter | 低〜中 | tree-sitter | 高 | 豊富 |
| E) Lezer | 中〜高 | Lezer | 高 | 限定的 |

### tree-sitter vs Lezer vs TextMate

| 観点 | TextMate | tree-sitter | Lezer |
|------|----------|-------------|-------|
| パース方式 | 正規表現 | LR/GLR | LR/GLR |
| 正確性 | トークンレベル | AST レベル | AST レベル |
| インクリメンタル | 行単位 | ノード単位 | ノード単位 |
| 実装言語 | - | C/Rust | JavaScript |
| grammar 数 | 200+ | 100+ | ~15 |
| theme エコシステム | VSCode 互換 | 独自 | 独自 |
| バンドルサイズ | 小 | 大 (WASM) | 中 |

## 推奨ロードマップ

### Phase 1: JS FFI プロトタイプ

```
目標: 動作するハイライターを素早く実装

MoonBit API
    ↓
JS Binding (extern "js")
    ↓
shiki / vscode-textmate
```

- 既存の grammar/theme を使用
- API 設計を検証

### Phase 2: トークナイザーの MoonBit 化

```
目標: コア処理を MoonBit に移植

MoonBit Tokenizer
    ↓
Regex Engine (外部)
    ↓
oniguruma-to-es or Oniguruma WASM
```

- 状態管理を MoonBit で実装
- 正規表現は外部エンジンに委譲

### Phase 3: 正規表現エンジンの内製化（オプション）

```
目標: 完全な MoonBit 実装

MoonBit Tokenizer
    ↓
MoonBit Regex (拡張版)
```

- 必要な Oniguruma 機能を実装
- パフォーマンス最適化

## 参考資料

- [Shiki 公式ドキュメント](https://shiki.style/guide/)
- [TextMate Language Grammars](https://macromates.com/manual/en/language_grammars)
- [vscode-textmate](https://github.com/microsoft/vscode-textmate)
- [oniguruma-to-es](https://github.com/slevithan/oniguruma-to-es)
- [Writing a TextMate Grammar](https://www.apeth.com/nonblog/stories/textmatebundle.html)
- [VS Code Syntax Highlight Guide](https://code.visualstudio.com/api/language-extensions/syntax-highlight-guide)
- [MoonBit Regex 実装](https://www.moonbitlang.com/pearls/moonbit-regex)

## vscode-textmate 実装詳細

### 主要クラス

| クラス | 役割 |
|--------|------|
| `Grammar` | grammar 管理、ルール登録、トークナイズ実行 |
| `StateStackImpl` | 行間の状態を linked list で管理 |
| `AttributedScopeStack` | スコープ階層＋属性を保持 |
| `LineTokens` | 行単位のトークン生成・集約 |

### StateStackImpl の構造

```typescript
class StateStackImpl {
  ruleId: RuleId;              // 現在のルール識別子
  nameScopesList: ScopeStack;  // "name" 属性のスコープ
  contentNameScopesList: ScopeStack;  // "contentName" のスコープ
  enterPos: number;            // 行内での開始位置
  anchorPos: number;           // アンカー位置
  beginRuleCapturedEOL: boolean;  // 改行をキャプチャしたか
  parent: StateStackImpl | null;  // 親状態（linked list）
}
```

### トークナイズフロー

```
tokenizeLine(line, prevState)
    ↓
_tokenize(line, prevState, emitBinaryTokens)
    ↓
_tokenizeString(line, isFirstLine, linePos, stack, lineTokens)
    ↓
各パターンをマッチング → 最良のマッチを選択
    ↓
begin なら push_state / end なら pop_state
    ↓
LineTokens にトークンを追加
```

### 注入 (Injections) グラマー

外部 grammar を動的に注入する機能：

```typescript
// HTML 内の CSS/JS など
{
  "injections": {
    "L:source.js": {
      "patterns": [...]
    }
  }
}
```

`_collectInjections()` がセレクタとパターンのペアを収集し、マッチ時に動的にマージ。

### トークン属性のエンコード

パフォーマンスのため、トークン属性をビットフィールドで圧縮：

```typescript
// EncodedTokenAttributes (32bit)
// [languageId:8][tokenType:8][fontStyle:3][foreground:9][background:9]
```

## MoonBit regex の詳細調査

### 確認済みサポート機能

| 機能 | サポート | 確認方法 |
|------|---------|---------|
| 基本パターン `a(bc|de)f` | ✅ | ドキュメント例 |
| 文字クラス `\d`, `\w` | ✅ | ドキュメント例 |
| 名前付きキャプチャ `(?<name>...)` | ✅ | ドキュメント例 |
| Unicode プロパティ `\p{Letter}` | ✅ | ドキュメント例 |
| 量指定子 `+`, `*`, `?`, `{n,m}` | ✅ | ドキュメント例 |

### 未確認・ドキュメント記載なし

| 機能 | サポート | 備考 |
|------|---------|------|
| 先読み `(?=...)` `(?!...)` | ❓ | ドキュメントに記載なし |
| 後読み `(?<=...)` `(?<!...)` | ❓ | ドキュメントに記載なし |
| バックリファレンス `\1` | ❓ | ドキュメントに記載なし |
| `\G` アンカー | ❌ | 実装困難と推測 |
| `^`, `$` アンカー | ❓ | 未確認 |

### lexmatch 構文（言語組み込み）

MoonBit には `lexmatch` という言語レベルの正規表現構文がある：

```moonbit
// デフォルトモード（トップダウン、re2スタイル）
lexmatch s {
  (_, "re1" ("re2" as r), _) => ...
  "re3" => ...  // 暗黙的に ^ と $
}

// longest モード（POSIX、最長マッチ）
lexmatch s using longest {
  ("re1" ("re2" as re2), next) => ...
}
```

**注意**: `lexmatch` はコンパイル時に処理される DSL で、`@regex.compile()` とは異なる。

## tree-sitter ハイライティングの仕組み

### クエリベースのハイライティング

tree-sitter は `.scm` (Scheme) ファイルでハイライトルールを定義：

```scheme
; highlights.scm
"func" @keyword
(type_identifier) @type
(function_name) @function
(string_literal) @string
(comment) @comment
```

### 3種類のクエリファイル

| ファイル | 役割 |
|---------|------|
| `highlights.scm` | ノードにハイライト名を割り当て |
| `locals.scm` | スコープと変数追跡（定義/参照の区別） |
| `injections.scm` | 言語埋め込み（HTML内のJS等） |

### locals.scm の例

```scheme
; スコープを導入するノード
(function_definition) @local.scope

; 変数定義
(parameter name: (identifier) @local.definition)

; 変数参照
(identifier) @local.reference
```

### TextMate との違い

| 観点 | TextMate | tree-sitter |
|------|----------|-------------|
| マッチ対象 | テキスト（正規表現） | AST ノード |
| スコープ体系 | `source.js`, `keyword.control` | `@keyword`, `@function` |
| 精度 | トークンレベル | 構文レベル |
| 定義/参照の区別 | 困難 | `locals.scm` で可能 |

### theme マッピング

```json
{
  "theme": {
    "keyword": "#C678DD",
    "function": "#61AFEF",
    "string": "#98C379",
    "comment": { "color": "#5C6370", "italic": true }
  }
}
```

## このプロジェクトへの適用

### 現状の構成

```
markdown.mbt/
├── src/           # MoonBit パーサー実装
├── js/api.js      # JS API ラッパー
└── target/js/     # ビルド出力
```

既存の `js/api.js` は MoonBit で実装した Markdown パーサーの JS バインディング。

### ハイライティング追加の選択肢

#### 選択肢1: Shiki 統合（最小工数）

```javascript
// js/api.js に追加
import { codeToHtml } from 'shiki';

export async function highlightCode(code, lang) {
  return await codeToHtml(code, { lang, theme: 'github-dark' });
}
```

- FencedCode ブロックのレンダリング時に呼び出し
- 完全な TextMate 互換
- 非同期 API

#### 選択肢2: tree-sitter MoonBit バインディング

```moonbit
// src/highlight.mbt
fn highlight_code(code: String, lang: String) -> Array[Token] {
  let parser = @tree_sitter.Parser::new()
  let language = get_language(lang)  // 言語ごとの grammar
  parser.set_language(language)
  let tree = parser.parse_string(code)

  // クエリでハイライト
  let query = @tree_sitter.Query::new(language, highlights_scm)
  let captures = query.captures(tree.root_node())

  // Token に変換
  captures.map(fn(c) { Token { ... } })
}
```

- MoonBit ネイティブ
- C バインディング必要（WASM/Native）

#### 選択肢3: 簡易ハイライター（自前実装）

```moonbit
// 言語ごとに lexmatch でトークナイズ
fn highlight_js(code: StringView) -> Array[Token] {
  let tokens = []
  for rest = code {
    lexmatch rest {
      ("//[^\n]*", next) => { tokens.push(Token::Comment(...)); continue next }
      ("\"[^\"]*\"", next) => { tokens.push(Token::String(...)); continue next }
      ("\\b(function|const|let|var)\\b", next) => { tokens.push(Token::Keyword(...)); continue next }
      (_, next) => continue next
    }
  }
  tokens
}
```

- 完全 MoonBit ネイティブ
- 言語ごとに実装が必要
- TextMate/tree-sitter より精度が低い

### 推奨アプローチ

**Phase 1**: Shiki 統合（JS レイヤーで）
- `toHtml()` 内で FencedCode を検出し Shiki でハイライト
- 素早く動作確認可能

**Phase 2**: tree-sitter バインディング活用
- `tonyfettes/tree_sitter` を使用
- MoonBit 側でハイライト処理
- より統合されたアーキテクチャ

## Lezer MoonBit 移植計画

### なぜ Lezer か

| 観点 | tree-sitter | Lezer | 選択理由 |
|------|-------------|-------|---------|
| 実装言語 | C/Rust | TypeScript | TS は読みやすく移植しやすい |
| コードサイズ | 大 | 小（~3000行） | 移植工数が少ない |
| 設計思想 | 汎用 | Web/エディタ特化 | markdown.mbt と親和性高い |
| 構文木 | 詳細 AST | コンパクト（64bit/node） | メモリ効率重視 |
| インクリメンタル | あり | あり | 両方対応 |

### Lezer コアアーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│  @lezer/generator                                           │
│  .grammar ファイル → パーサーテーブル生成                      │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  @lezer/lr (ランタイム)                                      │
│  ├─ LRParser: パーサーテーブルを実行                          │
│  ├─ Stack: LR スタック管理                                   │
│  └─ PartialParse: インクリメンタルパース                       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  @lezer/common (構文木)                                      │
│  ├─ Tree: 構文木ルート                                       │
│  ├─ TreeBuffer: コンパクトノード格納（Uint16Array）            │
│  ├─ TreeCursor: 効率的な走査                                  │
│  └─ SyntaxNode: ノード参照                                    │
└─────────────────────────────────────────────────────────────┘
```

### markdown.mbt との親和性

現在の markdown.mbt は CST ベース：

```moonbit
// markdown.mbt の Span
pub(all) struct Span {
  from : Int
  to : Int
}

// Lezer 互換の設計
pub(all) struct NodeType {
  id : Int
  name : String
}

pub(all) struct TreeNode {
  node_type : NodeType
  from : Int      // Span.from と互換
  to : Int        // Span.to と互換
  children : Array[TreeNode]
}
```

**共通点**:
- 位置情報（from/to）の概念が一致
- 入れ子構造（children）
- 型情報の付与

**設計方針**:
1. Lezer の Tree/TreeBuffer を MoonBit で実装
2. markdown.mbt の Span と互換性を持たせる
3. TreeCursor で効率的な走査を提供

### MoonBit 移植の設計

#### Phase 1: 基本データ構造

```moonbit
// src/lezer/types.mbt

/// ノード型定義
pub(all) struct NodeType {
  id : Int
  name : String
  // props は後で追加
}

/// コンパクトな構文木（Lezer の TreeBuffer 相当）
/// 各ノード: [type_id, from, to, child_end_index] の4要素
pub(all) struct TreeBuffer {
  data : Array[Int]  // Uint16Array の代わり
  length : Int
}

/// 構文木
pub(all) enum Tree {
  Node(
    node_type~ : NodeType,
    from~ : Int,
    to~ : Int,
    children~ : Array[Tree]
  )
  Buffer(buffer~ : TreeBuffer, from~ : Int, to~ : Int)
}

/// 効率的な走査用カーソル
pub(all) struct TreeCursor {
  tree : Tree
  stack : Array[(Tree, Int)]  // (node, child_index)
  mut pos : Int
}
```

#### Phase 2: パーサーランタイム

```moonbit
// src/lezer/parser.mbt

/// LR パーサーのスタック
pub(all) struct Stack {
  states : Array[Int]       // 状態スタック
  values : Array[Tree]      // 値スタック
  mut pos : Int             // 入力位置
}

/// パーサーテーブル（事前生成）
pub(all) struct ParseTable {
  states : Array[StateRow]
  // goto, actions, etc.
}

/// パーサー
pub(all) struct Parser {
  table : ParseTable
  node_types : Array[NodeType]
}

pub fn Parser::parse(self : Parser, input : String) -> Tree
```

#### Phase 3: インクリメンタルパース

```moonbit
// src/lezer/incremental.mbt

/// 編集情報（markdown.mbt の EditInfo と互換）
pub(all) struct TreeEdit {
  from : Int
  to : Int
  new_length : Int
}

/// インクリメンタルパース
pub fn Parser::parse_incremental(
  self : Parser,
  old_tree : Tree,
  input : String,
  edits : Array[TreeEdit]
) -> Tree
```

### markdown.mbt 統合設計

```moonbit
// 将来の統合イメージ

// FencedCode ブロックのハイライト
fn highlight_fenced_code(block : Block) -> Array[HighlightToken] {
  guard block is FencedCode(info~, code~, span~) else { return [] }

  let lang = parse_language_info(info)
  let parser = get_parser_for_language(lang)  // Lezer パーサー
  let tree = parser.parse(code)

  // tree を走査してハイライトトークンを生成
  let tokens = []
  let cursor = tree.cursor()
  while cursor.next() {
    let highlight = get_highlight_for_node(cursor.node_type)
    if highlight.is_some() {
      tokens.push(HighlightToken {
        from: span.from + cursor.from,  // 元ドキュメント内の位置
        to: span.from + cursor.to,
        highlight: highlight.unwrap()
      })
    }
  }
  tokens
}
```

### 実装ロードマップ

| Phase | 内容 | 工数 | 依存関係 | 状態 |
|-------|------|------|---------|------|
| 1 | Tree/TreeBuffer/TreeCursor | 1週 | なし | ✅ 完了 |
| 2 | Stack/LR パーサー | 2週 | Phase 1 | 未着手 |
| 3 | インクリメンタルパース | 2週 | Phase 2 | 未着手 |
| 4 | Grammar DSL（簡易版） | 2週 | Phase 2 | 未着手 |
| 5 | ハイライトクエリ | 1週 | Phase 1 | 未着手 |
| 6 | markdown.mbt 統合 | 1週 | Phase 1, 5 | 未着手 |

**MVP（最小実装）**: Phase 1 + 手動パーサー + Phase 5 + Phase 6

### Phase 1 実装済み（src/lezer/）

```
src/lezer/
├── moon.pkg.json      # パッケージ設定
├── types.mbt          # コアデータ構造
├── types_test.mbt     # コアテスト（9件）
├── json.mbt           # JSON パーサー実装
├── json_test.mbt      # JSON テスト（14件）
├── highlight.mbt      # ハイライト機能
└── highlight_test.mbt # ハイライトテスト（10件）
```

**全33テスト pass**

**実装済み機能**:

*コアデータ構造*:
- `NodeType`: ノード型定義
- `Tree`: 構文木（Node/Leaf/Buffered）
- `TreeBuffer`: コンパクトノード格納
- `TreeCursor`: 効率的な走査
- `Tree::iter()`: 深さ優先イテレーション
- `Tree::resolve(pos)`: 位置からノード検索

*JSON パーサー（リファレンス実装）*:
- `JsonTokenizer`: トークナイザー
- `JsonParser`: 再帰下降パーサー
- `parse_json(source)`: JSON → Tree

*ハイライト*:
- `HighlightTag`: 標準ハイライトタグ（String, Number, Keyword 等）
- `Highlighter`: ノード→タグ マッピング
- `highlight_json(source)`: JSON ハイライトトークン生成
- `highlight_json_to_html(source)`: HTML 出力

**使用例**:

```moonbit
// JSON をパースしてハイライト
let html = highlight_json_to_html("{\"name\": \"test\", \"count\": 42}")
// => <span class="hl-brace">{</span><span class="hl-property">"name"</span>...
```

### 参考実装

- [Lezer LR ランタイム](https://github.com/lezer-parser/lr) (~2000行 TS)
- [Lezer Common](https://github.com/lezer-parser/common) (~1000行 TS)
- [Lezer リファレンス](https://lezer.codemirror.net/docs/ref/)

## 未調査項目

- [x] vscode-textmate の詳細な実装（ソースコード解析）
- [ ] oniguruma-to-es の変換ロジック詳細
- [x] MoonBit regex の先読み/後読みサポート状況（ドキュメントに記載なし）
- [x] tree-sitter の MoonBit バインディング（tonyfettes/tree_sitter 存在確認）
- [x] tree-sitter ハイライティングの仕組み（クエリベース）
- [ ] MoonBit regex のソースコード解析（先読み/後読みの実装有無）
- [ ] tonyfettes/tree_sitter の実際の使用例
- [x] Lezer の MoonBit 移植可能性（設計完了）
