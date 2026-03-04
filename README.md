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

### screenshot

pr-creator が UI 変更の Before/After スクリーンショットを撮影するために使うユーティリティスキル。Playwright ベース。

**Features:**
- Single URL or batch capture with JSON array
- Configurable viewport size (default: 1440x900)
- Full-page or viewport-only capture
- Wait for CSS selectors before capturing

## Installation

```bash
claude /plugin marketplace add https://github.com/reibomaru/agent-plugins
claude /plugin install smart-committer@agent-plugins
claude /plugin install pr-creator@agent-plugins
claude /plugin install screenshot@agent-plugins
```

## Usage

変更をコミットしたいとき：

```
「変更をコミットして」
```

Claude が smart-committer エージェントを自動起動し、変更を論理的な単位に整理してコミットします。

PR を作成したいとき：

```
「PRを作って」
```

Claude が pr-creator エージェントを自動起動し、ベースブランチの検出・日本語 PR 説明の生成・UI 変更時のスクリーンショット撮影まで行います。

## License

MIT
