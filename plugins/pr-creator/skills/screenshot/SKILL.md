---
description: >
  Webページのスクリーンショットを Playwright で撮影するユーティリティスキル。
  pr-creator エージェントが PR 作成時に UI 変更のスクリーンショットを撮る際に利用する。
  単一URLでもURLリストでも対応可能。
disable-model-invocation: true
---

# Screenshot Skill

Playwright を使ってWebページのスクリーンショットを撮影するユーティリティ。
主に pr-creator エージェントから、UI 変更の Before/After スクリーンショットを撮るために呼び出される。

---

## 依存パッケージの確認

このスキルディレクトリに `node_modules/` がなければ以下を実行する：

```bash
cd <skill-dir> && npm install && npx playwright install chromium
```

## 使い方

スクリプトは **このスキルディレクトリから実行する**（node_modules の解決のため）。

### 単一ページ

```bash
node scripts/capture.mjs \
  --url <target-url> \
  --name <filename> \
  --out <output-dir>
```

### 複数ページ（バッチ）

```bash
node scripts/capture.mjs \
  --urls '[{"name":"<name>","url":"<url>"},...]' \
  --out <output-dir>
```

---

## オプション一覧

| オプション | デフォルト | 説明 |
|---|---|---|
| `--url <url>` | — | 単一URLを指定 |
| `--urls <json>` | — | `[{name, url}]` の JSON 配列 |
| `--name <name>` | `screenshot` | `--url` 使用時のファイル名（拡張子なし） |
| `--out <dir>` | `./screenshots` | 出力ディレクトリ |
| `--width <px>` | `1440` | ビューポート幅 |
| `--height <px>` | `900` | ビューポート高さ |
| `--no-full-page` | （なし） | フルページ撮影を無効化 |
| `--wait <ms>` | `500` | ページ読み込み後の待機時間（ms） |
| `--wait-selector <sel>` | — | 指定CSSセレクタが現れるまで待機 |

---

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| `Cannot find module 'playwright'` | このスキルディレクトリで `npm install` を実行 |
| `Executable doesn't exist` | `npx playwright install chromium` を実行 |
| タイムアウトエラー | dev サーバーが起動しているか確認。`--wait 1000` で待機時間を増やす |
| 画像が真っ白 | `--wait 1500` で待機時間を増やす |
| 要素が欠けている | `--wait-selector ".main-content"` で特定要素の出現を待つ |
