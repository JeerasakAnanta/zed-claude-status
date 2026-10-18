#!/usr/bin/env bash
# Claude Code status line. Reads session JSON on stdin, prints one line:
#   folder | branch | model | [██░░░░░░░░] 21%
# Usage (settings.json): "statusLine": { "type": "command", "command": "bash /path/to/statusline.sh" }
# Optional: CLAUDE_CONTEXT_LIMIT overrides the assumed context window size (default 200000).
input=$(cat)

model=$(jq -r '.model.display_name // .model.id // "?"' <<<"$input")
dir=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
pct=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
limit=$(jq -r '.context_window.context_window_size // empty' <<<"$input")
limit="${limit:-${CLAUDE_CONTEXT_LIMIT:-200000}}"

# Fall back to the latest assistant turn's token usage when Claude Code doesn't send a percentage.
if [ -z "$pct" ] && [ -n "$transcript" ] && [ -f "$transcript" ]; then
  tokens=$(tail -n 200 "$transcript" | jq -rs '
    [.[] | select(.type=="assistant" and .message.usage)] | last
    | .message.usage
    | (.input_tokens + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0))
    // empty' 2>/dev/null)
  [ -n "$tokens" ] && pct=$(awk -v t="$tokens" -v l="$limit" 'BEGIN { printf "%d", t * 100 / l }')
fi
pct=$(awk -v p="${pct:-0}" 'BEGIN { p = int(p); if (p > 100) p = 100; print p }')

folder="${dir##*[/\\]}"
branch=""
[ -n "$dir" ] && branch=$(git -C "$dir" branch --show-current 2>/dev/null)

filled=$((pct / 10))
bar=""
for i in 1 2 3 4 5 6 7 8 9 10; do
  if [ "$i" -le "$filled" ]; then bar="$bar█"; else bar="$bar░"; fi
done

printf '%s | %s | %s | [%s] %s%%\n' "${folder:-?}" "${branch:-no-git}" "$model" "$bar" "$pct"
