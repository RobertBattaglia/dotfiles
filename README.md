# 🏠 Dotfiles

Personal development environment configuration managed with [GNU Stow](https://www.gnu.org/software/stow/). Supports both macOS and Linux (Ubuntu/Debian).

## 📦 What's Included

- **Shell**: Zsh with [Oh My Zsh](https://ohmyzsh.sh/) (robbyrussell theme)
- **Terminal Multiplexer**: Tmux with custom keybindings and status bar
- **Editor**: Neovim (using [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) fork)
- **Version Control**: Git with GPG signing enabled
- **GPG Agent**: Configured with 1-week passphrase caching for seamless commit signing
- **Custom Scripts**: Productivity tools for tmux sessions, AI commit messages, clipboard management, and more

## 🚀 Quick Start

### One-Step Installation

Download and run the bootstrap script on a fresh system:

```bash
curl -O https://raw.githubusercontent.com/RobertBattaglia/dotfiles/main/bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh
```

The bootstrap script will:
- ✅ Install GitHub CLI
- ✅ Generate SSH key if needed
- ✅ Authenticate with GitHub (supports 2FA via browser or Personal Access Token for SSH sessions)
- ✅ Add SSH key to your GitHub account
- ✅ Clone this repository with submodules
- ✅ Install all required packages (stow, tmux, neovim, fzf, ripgrep, etc.)
- ✅ Set up Oh My Zsh and nvm
- ✅ Import GPG keys from Keybase
- ✅ Symlink all dotfiles using Stow

**For SSH sessions without browser access:**
When prompted, create a Personal Access Token at https://github.com/settings/tokens/new with scopes: `repo`, `admin:public_key`, `read:org`

### Post-Installation

1. **Install a Nerd Font** (required for terminal icons):
   - Download from [Nerd Fonts](https://www.nerdfonts.com/)
   - macOS: Copy to `~/Library/Fonts`
   - Linux: Copy to `~/.local/share/fonts`

2. **Configure your terminal** to use the installed Nerd Font

3. **Trust your GPG key**:
   ```bash
   gpg --edit-key 613BED3B035FB1AD0CB1A1063C50DE7686FB9E60 # this is my public pgp key
   gpg> fpr        # verify fingerprint
   gpg> trust      # choose 5 = I trust ultimately
   gpg> save
   ```

## 🛠️ Management

### Using Stow

```bash
# Stow a specific package
stow zsh

# Restow all packages
for dir in */; do [ -d "$dir" ] && stow -v "$dir"; done

# Remove a stowed package
stow -D tmux
```

### Updating Neovim Config

The neovim configuration is managed as a git submodule:

```bash
# Update to latest commit
git submodule update --remote

# Commit the updated submodule reference
git add nvim/.config/nvim
git commit -m "Update nvim submodule"
```

## 🔧 Custom Scripts

Located in `~/.local/bin`:

| Script | Description |
|--------|-------------|
| `tmux-sessionizer` | Fuzzy find and switch between tmux sessions (bound to `<prefix>f`) |
| `gcmgen` | Generate AI-powered commit messages using Cody CLI |
| `contributizer` | Visualize git blame statistics by author |
| `copy` | Cross-platform clipboard utility |
| `rsc` | Rsync wrapper for remote syncing (set `RSC_HOST` to configure) |
| `tmux-windowizer` | Fuzzy find tmux windows across all sessions by name, directory, or pane title; jump or create (bound to `<prefix>Space`). Pinned windows first, then closed pinned Claude threads (Enter resumes); ctrl-t pins |
| `claude-tmux-state` | Claude Code hook helper: records each session in the thread registry, tmux status colours, spoken alerts (see below) |
| `claude-threads` | Claude thread registry CLI: pin, snooze, settle, reopen closed sessions, backfill/auto-settle sweep (`claude-threads --help`) |
| `claude-threads-tick` | Status-bar timer that wakes expired snoozes (cheap; runs every `status-interval`) |
| `claude-tmux-speak` | Detached `say`/`afplay` announcement helper shared by the above |

## ⌨️ Key Bindings

### Tmux
- `<prefix>r` - Reload configuration
- `<prefix>Tab` - Switch to last session
- `<prefix>j/k` - Next/previous session
- `<prefix>f` - Launch tmux-sessionizer
- `<prefix>Space` - Launch tmux-windowizer
- `<prefix>w` - Tree view of sessions/windows (Claude windows coloured, see below)
- `<prefix>W` - Tree view of only Claude windows that are running or your turn (not settled; not snoozed unless awaiting approval)
- `<prefix>q` - Set a shortcut key for the current window in the tree view, shown as `[K]` in the status bar (empty clears; capital letters are safest). Remembered on the Claude thread and restored when it's reopened
- `<prefix>a` / `<prefix>A` - Clear Claude highlights for the current / all windows
- `<prefix>b` - Pin / unpin this window's Claude thread (`^`); prompts for a label, defaulting to Claude's task summary
- `<prefix>B` - Pinned threads picker: Enter jumps to the window, or resumes a closed thread in a new window (`claude --resume`, same launch flags, tree key restored); ctrl-t unpins, ctrl-e edits the label
- `<prefix>Z` - Snooze this thread (`30m`, `2h`, `14:30`, `9am`, `tomorrow`, `tomorrow 8am`, `mon`, `tonight`; empty or `wake` wakes)
- `<prefix>S` / `<prefix>X` - Settle this thread (done with it) and keep / kill the window

### Zsh Aliases
- `opengit` - Open current git repository in Chrome

## 🤖 Claude Code Hooks

Claude Code config isn't stowed (`~/.claude/settings.json` is rewritten by Claude Code and Indeed installers). Instead, manually merge these custom hooks into the `"hooks"` object in `~/.claude/settings.json`. If an event already has entries, append these to its array.

- **Tmux status indicators + spoken alerts + thread registry**: every hook calls `claude-tmux-state` (in `bin/`). It reads the hook JSON on stdin (the event comes from `hook_event_name`; the argument is only a fallback), records the session in the thread registry, and sets window options that `tmux.conf` renders in the status bar, `<prefix>w`/`<prefix>W`, and `tmux-windowizer`:

  | Event | State | Window | Spoken (macOS `say`), if it was running and you're not looking |
  |-------|-------|--------|------------------------------------------------------------------|
  | `UserPromptSubmit`, `PreToolUse`, `PostToolUse` | running | purple `●` | — |
  | `PermissionRequest`, `PreToolUse` of `AskUserQuestion` / `ExitPlanMode`, `Notification` `permission_prompt` / `elicitation_dialog` | needs approval | amber `◆` | `<window> needs approval` / `has a question` / `has a plan` |
  | `Stop` | done | green `✓` | `<window> done` |
  | `StopFailure` (API error ended the turn) | failed | red `✗` | `<window> failed, rate limited` (etc.) |
  | `PostToolUseFailure` with `is_interrupt` | interrupted | no colour | — |
  | `SessionStart` / `SessionEnd` | registered / closed | no colour | — |

  - Named windows are announced by name; auto-named windows by Claude's task summary (the pane title). Set `CLAUDE_TMUX_SPEAK=0` to mute, or `CLAUDE_TMUX_SPEAK_VOLUME` (default `0.6`, `1` = normal) to change loudness without touching system volume
  - Claude's `idle_prompt` reminder (`Notification`, ~60s after finishing) is ignored, so a finished turn stays green instead of being relabelled "needs input"
  - `Stop` doesn't fire when you interrupt with Esc mid-text, so the window stays purple until your next prompt (or `<prefix>a`)

- **Claude threads** (`claude-threads`): one JSON file per Claude session id in `~/.local/state/claude-threads/threads/`, so state survives closing the window and `claude --resume` (which keeps the session id).
  - **Pinned** (`^`): sorts first in the windowizer; closed pinned threads stay listed (`↺`) and reopen in one keystroke. Pinned threads never auto-settle
  - **Snoozed** (gray, `z`): no colour, no speech, hidden from `<prefix>W` until the wake time. If Claude finishes or fails meanwhile it shows `z!`. Approval prompts break through. On wake the window turns back to your-turn and announces `<window> snooze over` / `done while snoozed`. Typing a prompt wakes it early
  - **Settled** (dim): you're done with it; it leaves the active views but stays resumable. Closing a window does **not** settle. Threads idle more than 3 days auto-settle (`CLAUDE_THREADS_SETTLE_DAYS`, or `SETTLE_DAYS=` in `~/.local/state/claude-threads/config`); windows are never killed automatically. Typing a prompt into a settled thread un-settles it. Settling keeps pins and clears snoozes
  - **Sweep** (`claude-threads sweep`): backfills sessions from `~/.claude/projects/*/*.jsonl`, marks sessions whose Claude process died without `SessionEnd` as closed, and auto-settles. Runs at most hourly after a `Stop`, and on tmux `client-attached` at most every 30 minutes
  - Set `"cleanupPeriodDays": 3650` in `~/.claude/settings.json`: Claude Code deletes transcripts after 30 days by default, after which a thread can no longer be resumed

```json
{
  "cleanupPeriodDays": 3650,
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "~/.local/bin/claude-tmux-state || true" }] }
    ],
    "UserPromptSubmit": [
      { "hooks": [{ "type": "command", "command": "~/.local/bin/claude-tmux-state running || true" }] }
    ],
    "PreToolUse": [
      { "matcher": ".*", "hooks": [{ "type": "command", "command": "~/.local/bin/claude-tmux-state running || true" }] }
    ],
    "PostToolUse": [
      { "matcher": ".*", "hooks": [{ "type": "command", "command": "~/.local/bin/claude-tmux-state running || true" }] }
    ],
    "PostToolUseFailure": [
      { "matcher": ".*", "hooks": [{ "type": "command", "command": "~/.local/bin/claude-tmux-state || true" }] }
    ],
    "PermissionRequest": [
      { "hooks": [{ "type": "command", "command": "~/.local/bin/claude-tmux-state || true" }] }
    ],
    "Notification": [
      {
        "matcher": "permission_prompt|worker_permission_prompt|elicitation_dialog|elicitation_url_dialog",
        "hooks": [{ "type": "command", "command": "~/.local/bin/claude-tmux-state waiting || true" }]
      }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "~/.local/bin/claude-tmux-state idle || true" }] }
    ],
    "StopFailure": [
      { "hooks": [{ "type": "command", "command": "~/.local/bin/claude-tmux-state || true" }] }
    ],
    "SessionEnd": [
      { "hooks": [{ "type": "command", "command": "~/.local/bin/claude-tmux-state clear || true" }] }
    ]
  }
}
```

## 📝 Customization

- **Git**: Edit `git/.config/git/config` for user info and signing keys
- **GPG**: Configure `gnupg/.gnupg/gpg-agent.conf` for passphrase caching settings
- **Tmux**: Modify `tmux/.config/tmux/tmux.conf`
- **Zsh**: Update `zsh/.zshrc` and `zsh/.zsh_profile`
- **Scripts**: Add custom scripts to `bin/.local/bin/`

## 📚 Additional Documentation

See [CLAUDE.md](./CLAUDE.md) for detailed architecture and development guidance.
