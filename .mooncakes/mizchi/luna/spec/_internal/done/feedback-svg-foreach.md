# Luna SVG 名前空間での for_each 問題

## 問題

Luna の `for_each` を SVG 要素内で使用すると、DOM 階層エラーが発生する。

### エラーメッセージ

```
HierarchyRequestError: Failed to execute 'moveBefore' on 'Element':
State-preserving atomic move cannot be performed on nodes participating in an invalid hierarchy.

NotFoundError: Failed to execute 'removeChild' on 'Node':
The node to be removed is not a child of this node.
```

## 原因

`moveBefore` API が SVG 名前空間で例外をスローする場合があり、その際のフォールバック処理がなかった。

## 修正

### 1. moveBefore のフォールバック (move_before.mbt)

```javascript
// 修正前
if (typeof parent.moveBefore === 'function') {
  parent.moveBefore(node, refNode);
  return node;
}

// 修正後
if (typeof parent.moveBefore === 'function') {
  try {
    parent.moveBefore(node, refNode);
    return node;
  } catch (e) {
    // moveBefore may fail on SVG elements
    return parent.insertBefore(node, refNode);
  }
}
```

### 2. safe_remove_child の追加 (reconcile.mbt)

```javascript
// ノードが実際に親の子かチェックしてから削除
if (child.parentNode === parent) {
  parent.removeChild(child);
} else if (child.parentNode) {
  child.parentNode.removeChild(child);
}
```

## ステータス

✅ 修正済み
