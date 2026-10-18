# Prints a short Claude Code status for the latest session of the current directory, e.g. "sonnet-5-5 29%".
# Prints nothing when there is no session. Meant for a shell-prompt segment (see README).
param(
    [string]$Root = (Get-Location).Path,
    [int]$ContextLimit = $(if ($env:CLAUDE_CONTEXT_LIMIT) { [int]$env:CLAUDE_CONTEXT_LIMIT } else { 200000 })
)

$dir = Join-Path $HOME ".claude\projects\$($Root -replace '[^A-Za-z0-9]', '-')"
$file = Get-ChildItem $dir -Filter *.jsonl -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $file) { return }

$last = $null
$lines = @(Get-Content $file.FullName -Tail 100)
for ($i = $lines.Count - 1; $i -ge 0; $i--) {
    if ($lines[$i] -notmatch '"usage"' -or $lines[$i] -notmatch '"type":"assistant"') { continue }
    try { $entry = $lines[$i] | ConvertFrom-Json } catch { continue }
    if ($entry.message.usage) { $last = $entry.message; break }
}
if (-not $last) { return }

$u = $last.usage
$tokens = [int]$u.input_tokens + [int]$u.cache_read_input_tokens + [int]$u.cache_creation_input_tokens
$pct = [Math]::Min(100, [int][Math]::Floor($tokens * 100 / $ContextLimit))
"$($last.model -replace '^claude-', '') $pct%"
