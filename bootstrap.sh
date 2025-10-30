#!/bin/bash

set -e  # Exit on any error

echo "=== Dotfiles Bootstrap Script ==="
echo "This script will:"
echo "1. Install GitHub CLI (gh)"
echo "2. Generate SSH key if needed"
echo "3. Authenticate with GitHub (supports 2FA)"
echo "4. Add SSH key to your GitHub account"
echo "5. Clone dotfiles repository"
echo "6. Run install.sh"
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo "Unsupported operating system"
    exit 1
fi

# Get GitHub username
read -p "Enter your GitHub username [RobertBattaglia]: " GITHUB_USERNAME
GITHUB_USERNAME=${GITHUB_USERNAME:-RobertBattaglia}

# Optional: Repository name (defaults to dotfiles)
read -p "Enter repository name [dotfiles]: " REPO_NAME
REPO_NAME=${REPO_NAME:-dotfiles}

DOTFILES_DIR="$HOME/$REPO_NAME"

# Check if dotfiles already exist
if [ -d "$DOTFILES_DIR" ]; then
    echo "Directory $DOTFILES_DIR already exists!"
    read -p "Do you want to continue anyway? (y/N): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo "Aborting."
        exit 1
    fi
fi

# Install GitHub CLI
echo ""
echo "=== Installing GitHub CLI ==="
if command -v gh &> /dev/null; then
    echo "GitHub CLI already installed: $(gh --version | head -n1)"
else
    if [[ $OS == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install gh
    else
        # Install gh on Linux
        sudo apt-get update
        sudo apt-get install -y curl
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y gh
    fi
fi

# Generate SSH key if it doesn't exist
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
echo ""
echo "=== Checking for SSH key ==="
if [ -f "$SSH_KEY_PATH" ]; then
    echo "SSH key already exists at $SSH_KEY_PATH"
else
    echo "Generating new SSH key..."
    ssh-keygen -t ed25519 -C "$GITHUB_USERNAME@github" -f "$SSH_KEY_PATH" -N ""
    echo "SSH key generated successfully!"
fi

# Start ssh-agent and add key
echo ""
echo "=== Adding SSH key to ssh-agent ==="
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY_PATH"

# Authenticate with GitHub
echo ""
echo "=== Authenticating with GitHub ==="

if gh auth status &> /dev/null; then
    echo "Already authenticated with GitHub CLI"
else
    # Check if we're in an SSH session
    if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        echo "SSH session detected - using Personal Access Token authentication"
        echo ""
        echo "Please create a token at: https://github.com/settings/tokens/new"
        echo "Required scopes: 'repo', 'admin:public_key', 'read:org'"
        echo "Token expiration: Choose based on your security preferences"
        echo ""
        read -sp "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
        echo
        if [ -z "$GITHUB_TOKEN" ]; then
            echo "Error: Token is required"
            exit 1
        fi
        echo "$GITHUB_TOKEN" | gh auth login --with-token
    else
        echo "This will open a browser window for OAuth authentication (supports 2FA)"
        echo "If already authenticated, this will skip to the next step."
        echo ""
        gh auth login --git-protocol ssh --web
    fi
fi

# Upload SSH key to GitHub
echo ""
echo "=== Adding SSH key to GitHub account ==="
SSH_PUBLIC_KEY=$(cat "${SSH_KEY_PATH}.pub")
KEY_TITLE="dotfiles-setup-$(hostname)-$(date +%Y%m%d)"

# Check if key already exists
if gh ssh-key list | grep -q "$KEY_TITLE"; then
    echo "SSH key '$KEY_TITLE' already exists on GitHub"
else
    echo "Uploading SSH key to GitHub..."
    echo "$SSH_PUBLIC_KEY" | gh ssh-key add - --title "$KEY_TITLE"
    echo "SSH key added successfully!"
fi

# Test SSH connection
echo ""
echo "=== Testing SSH connection to GitHub ==="
ssh -T git@github.com || true  # This command returns non-zero even on success

# Clone dotfiles repository
echo ""
echo "=== Cloning dotfiles repository ==="
if [ -d "$DOTFILES_DIR/.git" ]; then
    echo "Repository already cloned at $DOTFILES_DIR"
    cd "$DOTFILES_DIR"
    echo "Pulling latest changes..."
    git pull
else
    git clone "git@github.com:${GITHUB_USERNAME}/${REPO_NAME}.git" "$DOTFILES_DIR"
    cd "$DOTFILES_DIR"
fi

# Initialize submodules
echo ""
echo "=== Initializing git submodules ==="
git submodule update --init --recursive

# Run install.sh
echo ""
echo "=== Running install.sh ==="
if [ -f "./install.sh" ]; then
    chmod +x ./install.sh
    ./install.sh
else
    echo "Warning: install.sh not found in repository"
fi

echo ""
echo "=== Bootstrap complete! ==="
echo "Your dotfiles have been set up successfully."
