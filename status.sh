#!/usr/bin/env bash
# Usage: status.sh <project-root>
root="${1:-$PWD}"
dir="$HOME/.claude/projects/$(printf '%s' "$root" | sed 's/[^A-Za-z0-9]/-/g')"
f=$(ls -t "$dir"/*.jsonl 2>/dev/null | head -1)
[ -z "$f" ] && { echo "No Claude Code session found for $root"; exit 0; }
jq -rs '
  [.[] | select(.type=="assistant" and .message.usage)] as $a
  | ($a | last) as $l
  | ($l.message.usage) as $u
  | "Model: \($l.message.model)\nContext: \(($u.input_tokens + $u.cache_read_input_tokens + $u.cache_creation_input_tokens)) tokens\nTotal output: \([$a[].message.usage.output_tokens] | add) tokens\nTurns: \($a|length)\nBranch: \($l.gitBranch // "-")"
' "$f"
