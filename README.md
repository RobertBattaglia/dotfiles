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
| `tmux-windowizer` | Fuzzy find tmux windows across all sessions by name, directory, or pane title; jump or create (bound to `<prefix>Space`) |
| `claude-tmux-state` | Claude Code hook helper: tmux running/waiting window colours and spoken alerts (see below) |

## ⌨️ Key Bindings

### Tmux
- `<prefix>r` - Reload configuration
- `<prefix>Tab` - Switch to last session
- `<prefix>j/k` - Next/previous session
- `<prefix>f` - Launch tmux-sessionizer
- `<prefix>Space` - Launch tmux-windowizer
- `<prefix>w` - Tree view of sessions/windows (Claude windows coloured: purple = running, red = waiting/done)
- `<prefix>W` - Tree view of only Claude windows that are running or waiting
- `<prefix>q` - Set a shortcut key for the current window in the tree view, shown as `[K]` in the status bar (empty clears; capital letters are safest)
- `<prefix>a` / `<prefix>A` - Clear Claude highlights for the current / all windows

### Zsh Aliases
- `opengit` - Open current git repository in Chrome

## 🤖 Claude Code Hooks

Claude Code config isn't stowed (`~/.claude/settings.json` is rewritten by Claude Code and Indeed installers). Instead, manually merge these custom hooks into the `"hooks"` object in `~/.claude/settings.json`. If an event already has entries, append these to its array.

- **Tmux status indicators + spoken alerts**: every hook calls `claude-tmux-state` (in `bin/`), which sets window options that `tmux.conf` highlights in the status bar, `<prefix>w`/`<prefix>W`, and `tmux-windowizer`:

  | Hook | `claude-tmux-state` | Window | Spoken (macOS `say`) |
  |------|---------------------|--------|----------------------|
  | `UserPromptSubmit`, `PreToolUse`, `PostToolUse` | `running` | purple (`@claude_running`) | — |
  | `Notification` | `waiting` | red (`@claude_waiting`) | `<window> needs input`, if it was running |
  | `Stop` | `idle` | red (`@claude_waiting`) | `<window> done`, if it was running |
  | `SessionEnd` | `clear` | no colour | — |

  - Named windows are announced by name; auto-named windows by Claude's task summary (the pane title). Nothing is spoken for the window you're currently looking at. Set `CLAUDE_TMUX_SPEAK=0` to mute, or `CLAUDE_TMUX_SPEAK_VOLUME` (default `0.6`, `1` = normal) to change loudness without touching system volume
  - Claude's later idle reminder (`Notification`, ~60s after finishing) is a no-op: the window is already red and wasn't running, so nothing is spoken
  - `Stop` doesn't fire when you interrupt with Esc, so the window stays purple until your next prompt (or `<prefix>a`)
  - `<prefix>W` lists only Claude windows that are waiting or running; `<prefix>a` / `<prefix>A` clear both flags for the current / all windows

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.local/bin/claude-tmux-state waiting || true"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.local/bin/claude-tmux-state running || true"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.local/bin/claude-tmux-state running || true"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.local/bin/claude-tmux-state running || true"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.local/bin/claude-tmux-state idle || true"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.local/bin/claude-tmux-state clear || true"
          }
        ]
      }
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
