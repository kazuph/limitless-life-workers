/**
 * Web Components SSR - Type Definitions
 *
 * サーバー/クライアント共通の型定義
 * MoonBit FFI からも利用しやすい関数型インターフェース
 */

// ============================================
// Core Types
// ============================================

/**
 * コンポーネントの状態型
 */
export type State = Record<string, unknown>;

/**
 * イベントペイロード（クライアントサイドで生成）
 */
export interface EventPayload {
  type: string;
  target?: {
    value?: string;
    checked?: boolean;
    dataset?: Record<string, string>;
  };
}

/**
 * イベントハンドラ: 純粋関数として状態遷移を記述
 * (currentState, payload) => newState
 */
export type Handler<S extends State = State> = (
  state: S,
  payload: EventPayload
) => S;

/**
 * レンダー関数: 状態からHTML文字列を生成
 * 純粋関数であること
 */
export type RenderFn<S extends State = State> = (state: S) => string;

// ============================================
// Component Definition
// ============================================

/**
 * CSS配信戦略
 */
export type CSSStrategy = 'inline' | 'link' | 'link-preload' | 'adoptable';

/**
 * コンポーネント定義
 * クラスではなく純粋なオブジェクトとして定義
 */
export interface ComponentDef<S extends State = State> {
  /** カスタム要素名 (例: 'my-counter') */
  name: string;

  /** インラインCSS */
  styles: string;

  /** 外部CSSのパス (link/link-preload戦略用) */
  stylesUrl?: string;

  /** 初期状態 */
  initialState: S;

  /** レンダー関数 */
  render: RenderFn<S>;

  /** イベントハンドラのマップ */
  handlers: Record<string, Handler<S>>;

  /** 状態のシリアライザ (デフォルト: JSON.stringify) */
  serialize?: (state: S) => string;

  /** 状態のデシリアライザ (デフォルト: JSON.parse) */
  deserialize?: (str: string) => S;
}

// ============================================
// SSR Options
// ============================================

/**
 * SSRレンダラーのオプション
 */
export interface SSROptions {
  /** CSS配信戦略 */
  cssStrategy: CSSStrategy;

  /** CSSのベースURL */
  baseUrl?: string;
}

/**
 * SSRレンダリングのオプション
 */
export interface RenderOptions {
  /** Light DOMに配置するchildren */
  children?: string;
}

// ============================================
// Client Options
// ============================================

/**
 * クライアント登録のオプション
 */
export interface RegisterOptions {
  /** CSS配信戦略 (SSRと一致させる) */
  cssStrategy?: CSSStrategy;
}

// ============================================
// Helper Types (MoonBit FFI用)
// ============================================

/**
 * MoonBitから呼び出しやすい簡易インターフェース
 */
export interface SimpleComponentDef {
  name: string;
  styles: string;
  stylesUrl?: string;
  initialStateJson: string;
  // render/handlersは関数なのでFFI経由で別途渡す
}

/**
 * ハンドラ呼び出し結果
 */
export interface HandlerResult<S extends State = State> {
  newState: S;
  shouldRender: boolean;
}
