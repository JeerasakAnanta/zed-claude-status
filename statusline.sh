#!/usr/bin/env bash
# Claude Code status line. Reads session JSON on stdin, prints one line.
# Usage (settings.json): "statusLine": { "type": "command", "command": "bash /path/to/statusline.sh" }
input=$(cat)

model=$(jq -r '.model.display_name // .model.id // "?"' <<<"$input")
dir=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
cost=$(jq -r '.cost.total_cost_usd // empty' <<<"$input")

# Context size: tokens sent in the latest assistant turn (same as status.sh).
ctx=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  ctx=$(tail -n 200 "$transcript" | jq -rs '
    [.[] | select(.type=="assistant" and .message.usage)] | last
    | .message.usage
    | (.input_tokens + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0))
    // empty' 2>/dev/null)
fi

branch=""
[ -n "$dir" ] && branch=$(git -C "$dir" branch --show-current 2>/dev/null)

out="$model"
[ -n "$ctx" ] && out="$out | ctx $(awk -v n="$ctx" 'BEGIN { printf (n >= 1000 ? "%.1fk" : "%d"), (n >= 1000 ? n / 1000 : n) }')"
[ -n "$cost" ] && out="$out | \$$(printf '%.2f' "$cost")"
[ -n "$branch" ] && out="$out | $branch"
printf '%s\n' "$out"
