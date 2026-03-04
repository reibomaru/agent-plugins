# agent-plugins

A collection of Claude Code plugins for smart Git workflows.

## Plugins

### smart-committer

Organizes uncommitted changes into logical commit groups with a smart-committer agent and `/commit` skill.

**Features:**
- Analyzes staged and unstaged changes
- Groups changes into meaningful logical units (features, fixes, refactors, etc.)
- Flags questionable changes for user review
- Creates well-structured conventional commits
- Communicates in Japanese, commits in English

### pr-creator

Creates well-structured pull requests with automatic base branch detection and Japanese descriptions.

**Features:**
- Automatically detects base branch and confirms with user
- Commits uncommitted changes before PR creation
- Generates PR title (Conventional Commits, ≤30 chars) and Japanese description
- Captures and uploads screenshots for UI changes
- Checks for duplicate PRs

### conflict-guard

ファイル編集時にベースブランチとのマージコンフリクトリスクを自動検出する PreToolUse hook プラグイン。

**Features:**
- `Write`/`Edit` ツール実行前に自動で発火（プロンプト不要）
- ベースブランチの自動検出（`origin/main`, `origin/master`, `origin/develop`）
- `CONFLICT_GUARD_BASE_BRANCH` 環境変数でベースブランチを上書き可能
- 両ブランチが同一ファイルを変更している場合は HIGH リスクとして警告

## Installation

```bash
claude /plugin marketplace add https://github.com/reibomaru/agent-plugins
claude /plugin install smart-committer@agent-plugins
claude /plugin install pr-creator@agent-plugins
claude /plugin install conflict-guard@agent-plugins
```

## Usage

| Plugin | できること | プロンプト例 | 動作 |
|--------|-----------|-------------|------|
| **smart-committer** | 未コミットの変更を論理的な単位に分けてコミット | `変更をコミットして` | 変更を分析し、feature/fix/refactor 等に分類して conventional commit を作成 |
| | | `この作業分をコミットしたい` | 同上 |
| | | `/commit` | スキル経由で smart-committer を起動 |
| **pr-creator** | 現在のブランチから PR を作成 | `PRを作って` | ベースブランチ検出 → 確認 → 日本語で PR 説明を生成 → `gh pr create` |
| | | `この機能の実装が終わったからPRを作って` | 未コミット変更があれば先にコミットしてから PR 作成 |
| | | `mainブランチに向けてPR出して` | 指定ブランチをターゲットにして PR 作成 |
| | UI 変更時のスクリーンショット付き PR | `実装完了！PR作成お願い` | UI 変更を検出した場合、Before/After スクリーンショットを撮影して PR に添付 |
| **conflict-guard** | ファイル編集時にマージコンフリクトのリスクを警告 | *(自動実行 — プロンプト不要)* | `Write`/`Edit` ツール実行前に PreToolUse hook が発火し、ベースブランチとの差分を検査。コンフリクトリスクがあれば警告を表示 |

## License

MIT
