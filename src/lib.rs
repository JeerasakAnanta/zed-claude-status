use zed_extension_api::{
    self as zed, process::Command, SlashCommand, SlashCommandOutput, SlashCommandOutputSection,
    Worktree,
};

const SCRIPT: &str = "/home/game/1_projects/zed-claude-status/status.sh";

struct ClaudeStatus;

impl zed::Extension for ClaudeStatus {
    fn new() -> Self {
        ClaudeStatus
    }

    fn run_slash_command(
        &self,
        command: SlashCommand,
        _args: Vec<String>,
        worktree: Option<&Worktree>,
    ) -> Result<SlashCommandOutput, String> {
        if command.name != "claude-status" {
            return Err(format!("unknown command: {}", command.name));
        }
        let root = worktree.map(|w| w.root_path()).unwrap_or_default();
        let out = Command::new("bash")
            .arg(SCRIPT)
            .arg(root)
            .output()?;
        let text = String::from_utf8_lossy(&out.stdout).to_string();
        Ok(SlashCommandOutput {
            sections: vec![SlashCommandOutputSection {
                range: (0..text.len()).into(),
                label: "Claude status".to_string(),
            }],
            text,
        })
    }
}

zed::register_extension!(ClaudeStatus);
