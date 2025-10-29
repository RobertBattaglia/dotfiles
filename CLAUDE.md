# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that manages configuration files for zsh, git, tmux, neovim, and custom scripts using GNU Stow. The repository uses a git submodule for the neovim configuration (kickstart.nvim).

## Installation and Setup

Run the installation script:
```bash
./install.sh
```

This script:
- Detects OS (macOS via Homebrew or Linux via apt)
- Installs required packages: stow, tmux, neovim, fzf, ripgrep, gnupg, htop, xclip, unzip
- Installs Oh My Zsh
- Installs nvm (Node Version Manager)
- On Linux: builds and installs tmux-mem-cpu-load from source
- On Linux: installs Keybase
- Imports GPG keys from Keybase
- Uses stow to symlink all dotfiles to home directory

### Manual Post-Installation Steps

After running install.sh, you must:
1. Install a Nerd Font manually (copy to `~/Library/Fonts` on macOS or `~/.local/share/fonts` on Linux)
2. Configure terminal to use the Nerd Font
3. Trust the GPG key:
   ```bash
   gpg --edit-key 613BED3B035FB1AD0CB1A1063C50DE7686FB9E60
   gpg> fpr
   gpg> trust
   # Choose 5 = I trust ultimately
   gpg> save
   ```

## Repository Structure

The repository uses GNU Stow's directory structure where each top-level directory represents a package to be stowed:

- `zsh/` - Contains `.zshrc` and `.zsh_profile`
- `git/.config/git/` - Contains git `config` and `ignore` files
- `tmux/.config/tmux/` - Contains `tmux.conf`
- `nvim/.config/nvim/` - Git submodule pointing to kickstart.nvim fork
- `bin/.local/bin/` - Custom executable scripts

## Stow Management

To add/update dotfiles:
```bash
# Stow a specific package
stow zsh

# Restow all packages
for dir in */; do [ -d "$dir" ] && stow -v "$dir"; done

# Remove a stowed package
stow -D zsh
```

## Git Submodule Management

The neovim configuration is managed as a submodule (kickstart.nvim fork).

Update submodule to latest commit:
```bash
git submodule update --remote
```

Note: There's a typo in README.md ("sumodule" should be "submodule").

## Custom Scripts in bin/.local/bin/

- `tmux-sessionizer` - Fuzzy finder for creating/switching tmux sessions from directories (bound to `<prefix>f` in tmux)
- `gcmgen` - AI-powered commit message generator using Cody CLI; extracts ticket numbers from branch names and generates 5 commit message options
- `contributizer` - Python tool that uses git blame to generate a tree view of code contributions by author per file/directory
- `copy` - Cross-platform clipboard utility that works with xclip/xsel (Linux) or pbcopy (macOS)
- `rsc` - Rsync wrapper for syncing files to/from Indeed CVM (use `-r` flag for reverse sync); respects gitignore; set `RSC_HOST` environment variable to override default host
- `get-openai-api-key` - Retrieves OpenAI API key
- `ldappass` - Retrieves LDAP password

## Configuration Details

### Git Configuration
- Commits are GPG-signed by default
- Editor is nvim
- Auto-correct is enabled with 20 decisecond delay
- Excludes file: `~/.config/git/ignore`

### Tmux Configuration
- Prefix key: default (Ctrl-b)
- Custom keybindings:
  - `<prefix>r` - Reload tmux config
  - `<prefix>Tab` - Switch to last session
  - `<prefix>j/k` - Switch to next/previous session
  - `<prefix>f` - Open tmux-sessionizer popup
- Status bar at top with system stats (uptime, CPU/memory via tmux-mem-cpu-load)
- Mouse mode enabled
- Windows and panes numbered starting from 1

### Zsh Configuration
- Uses Oh My Zsh with "robbyrussell" theme
- Loads nvm (Node Version Manager)
- Includes terraform bash completion
- Alias: `opengit` - Opens current git remote in Chrome
- Sources `.zsh_profile` which adds `~/.local/bin` and `/opt/nvim-linux-x86_64/bin` to PATH
- Sets `GPG_TTY=$(tty)` for GPG signing
