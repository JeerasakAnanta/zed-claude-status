# Claude Status for Zed

A [Zed](https://zed.dev) extension that adds a `/claude-status` slash command to the Assistant panel. It shows the status of your latest [Claude Code](https://claude.com/claude-code) session for the current project:

```
Model: claude-sonnet-5-5
Context: 48210 tokens
Total output: 9314 tokens
Turns: 27
Branch: main
```

## How it works

1. The extension (`src/lib.rs`, Rust compiled to WASM) registers the `claude-status` slash command.
2. When the command runs, it calls `status.sh` with the worktree root.
3. The script finds the newest session log in `~/.claude/projects/<project-path>/*.jsonl` and uses `jq` to read the last assistant message's usage data.

## Requirements

- [Zed](https://zed.dev)
- [Rust](https://rustup.rs) installed through `rustup`, which Zed needs to build dev extensions
- `bash` and [`jq`](https://jqlang.github.io/jq/) on your `PATH`
- Claude Code, with at least one session in the project

## Install (dev extension)

```sh
git clone https://github.com/<your-username>/zed-claude-status.git
```

Before installing, edit the hardcoded script path in `src/lib.rs`. See [Known issues](#known-issues).

Then, in Zed:

1. Open the command palette and run `zed: install dev extension`.
2. Select the cloned `zed-claude-status` folder.
3. In the Assistant panel, type `/claude-status`.

## Always-visible status line (Claude Code in Zed's terminal)

Zed's extension API has no status bar API, so the extension can't add one. If you run `claude` in Zed's terminal, you can use Claude Code's own status line instead. `statusline.sh` prints something like:

```
Sonnet 5.5 | ctx 48.2k | $0.12 | main
```

Add this to `~/.claude/settings.json`, using the real path to your checkout:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /path/to/zed-claude-status/statusline.sh"
  }
}
```

It needs `bash` and `jq`. Restart `claude` after changing the settings.

## Project structure

| Path             | Purpose                                                        |
| ---------------- | -------------------------------------------------------------- |
| `extension.toml` | Extension manifest: id, slash command, and `process:exec` capability |
| `src/lib.rs`     | Extension code: registers the command and runs the script      |
| `status.sh`      | Reads the Claude Code session log and prints the summary       |
| `statusline.sh`  | One-line status for Claude Code's `statusLine` setting         |
| `Cargo.toml`     | Rust crate config (`cdylib`, uses `zed_extension_api`)         |

## Known issues

- **Hardcoded script path.** `SCRIPT` in `src/lib.rs` points to `/home/game/1_projects/zed-claude-status/status.sh`. Change it to match your checkout. Resolving the path automatically is a good first contribution.
- **Windows.** `status.sh` has only been written with a POSIX shell in mind. Windows support is untested.
- **Placeholder repository URL** in `extension.toml`. Update it to the real GitHub URL.

## Contributing

Contributions are welcome. Bug reports, ideas, and pull requests are all appreciated.

1. Fork the repository and create a branch: `git checkout -b my-feature`
2. Make your changes and test them as a dev extension in Zed.
3. Run `cargo fmt` and `cargo clippy --target wasm32-wasip2` before committing.
4. Open a pull request that says what changed and why.

### Ideas

- Locate `status.sh` without a hardcoded path
- Show cost estimates or context-window percentage
- Support choosing a specific session instead of the latest
- Windows support
- Replace the `jq`/`bash` dependency with native Rust parsing

For larger changes, please open an issue first so we can discuss the approach.

## License

[MIT](LICENSE)
