---
description: "PRのインラインコメントを分類して対応（修正/issue起票/返信）を一括で行う"
argument-hint: "<PR URL or number>"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
---

# PR インラインコメント対応コマンド

PRのレビューコメントを分析し、リアクション状況に応じて適切な対応を行います。

**対象PR:** $ARGUMENTS

## ワークフロー概要

```
PRコメント取得 → リアクション分類 → 並列対応 → 結果サマリー
```

## Step 1: PR情報とコメントの取得

以下のコマンドでPR情報を収集してください:

```bash
# PR URLからowner/repo/numberを抽出（URLまたは番号を受け付ける）
# 例: https://github.com/supsysjp/scenario-agent/pull/44 → supsysjp/scenario-agent 44
# 例: 44 → 現在のリポジトリの #44

# PR詳細
gh pr view <PR_NUMBER> --json number,title,url,headRefName,baseRefName

# インラインコメント一覧（リアクション情報含む）
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --jq '.[] | {
  id: .id,
  path: .path,
  line: .line,
  body: .body,
  user: .user.login,
  reactions_plus1: .reactions["+1"],
  in_reply_to_id: .in_reply_to_id,
  created_at: .created_at
}'

# 既存の返信を把握するため、全コメントのスレッド構造を確認
# in_reply_to_id が null のものがトップレベルコメント
# in_reply_to_id が設定されているものは返信
```

## Step 2: コメントの分類

取得したコメントを以下の4カテゴリに分類してください:

### カテゴリA: :+1: あり + あとで対応（issue起票）
- **条件**: `reactions["+1"] > 0` かつ、コメント本文に以下のキーワードを含む:
  - 「あとで」「後で」「別issue」「別のissue」「TODO」「将来的に」「今後」「スコープ外」
  - 「リファクタ」を含む改善提案
  - SRP違反やアーキテクチャ改善等の大規模リファクタリング提案
- **対応**: `pr-issue-creator` エージェントで issue 起票 → コメントに issue リンクを返信

### カテゴリB: :+1: あり + コード修正が必要
- **条件**: `reactions["+1"] > 0` かつ、カテゴリAに該当しない
- **対応**: コードを修正 → commit & push → `pr-comment-responder` エージェントで commit hash を含めて返信

### カテゴリC: リアクションなし + 対応すべき
- **条件**: `reactions["+1"] == 0` かつ、以下のいずれかに該当:
  - セキュリティに関する指摘
  - バグの指摘
  - 明確なコード品質上の問題
- **対応**: `pr-issue-creator` エージェントで issue 起票

### カテゴリD: リアクションなし + 対応不要
- **条件**: 上記いずれにも該当しない
- **対応**: `pr-comment-responder` エージェントで未対応の旨を返信

## Step 3: 分類結果の確認

分類結果を以下の形式でユーザーに提示し、確認を得てください:

```markdown
## コメント分類結果

### カテゴリA: Issue起票 (X件)
- [ ] #{comment_id} @{path}:L{line} - {コメント概要}

### カテゴリB: コード修正 (X件)
- [ ] #{comment_id} @{path}:L{line} - {コメント概要}

### カテゴリC: 要対応（リアクションなし）→ Issue起票 (X件)
- [ ] #{comment_id} @{path}:L{line} - {コメント概要}

### カテゴリD: 未対応返信 (X件)
- [ ] #{comment_id} @{path}:L{line} - {コメント概要}

この分類で進めてよいですか？
```

**重要**: 分類が曖昧な場合は、必ずユーザーに確認してから進めてください。

## Step 4: 対応の実行

ユーザーの確認後、以下の順序で対応を実行します。
**可能な限り並列で実行してください。**

### 4-1. カテゴリB: コード修正（メインエージェントで実行）

1. 対象ファイルを読み、コメントの指摘内容を理解
2. コードを修正（Edit tool使用）
3. 修正完了後、まとめて1つのcommitを作成:
   ```bash
   git add <modified-files>
   git commit -m "refactor: PRコメント対応 - <変更概要>"
   git push
   ```
4. commit hashを記録

### 4-2. カテゴリA + C: Issue起票（並列でsub-agent実行）

`pr-issue-creator` エージェントを使って、各コメントに対するissueを**並列**で起票:

```
Task(pr-issue-creator): "PR #{pr_number} のコメント #{comment_id} について issue を起票してください。
コメント内容: {comment_body}
対象ファイル: {path}:L{line}
PR URL: {pr_url}"
```

### 4-3. 全カテゴリ: PRコメントへの返信（並列でsub-agent実行）

全カテゴリの返信を `pr-comment-responder` エージェントで**並列**実行:

- **カテゴリA**: `📌 Issue起票完了: #{issue_number} で対応予定`
- **カテゴリB**: `✅ 対応完了 (commit: {commit_hash})\n\n{修正内容の概要}`
- **カテゴリC**: `📌 Issue起票完了: #{issue_number} で対応予定`
- **カテゴリD**: `📝 本PRでは未対応としました。必要に応じて別途対応を検討します。`

返信のフォーマット:
```
Task(pr-comment-responder): "PR #{pr_number} の以下のコメントに返信してください。
コメントID: {comment_id}
返信内容: {reply_body}"
```

## Step 5: 結果サマリー

全ての対応完了後、以下の形式で結果を報告してください:

```markdown
## 対応完了サマリー

### 修正済み（commit: {hash}）
- {path}:L{line} - {修正内容}

### Issue起票済み
- #{issue_number}: {issue_title} ← コメント @{path}:L{line}

### 未対応返信済み
- {path}:L{line} - {理由}

### 統計
| カテゴリ | 件数 |
|---------|------|
| コード修正 | X件 |
| Issue起票 | X件 |
| 未対応返信 | X件 |
| **合計** | **X件** |
```

## 注意事項

- **スレッド内の返信はスキップ**: `in_reply_to_id` が設定されているコメント（=他のコメントへの返信）はトップレベルコメントではないため、対応対象外とする
- **既に返信済みのコメントはスキップ**: そのコメントIDに対する返信が既に存在する場合はスキップ
- **commit は1つにまとめる**: カテゴリBの修正は可能な限り1つのcommitにまとめ、コメントごとに個別commitは作らない
- **push前にテスト**: コード修正後は可能であればテストを実行して確認
- **返信の言語**: 元コメントの言語に合わせる（日本語コメントには日本語で返信）
