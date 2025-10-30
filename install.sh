#!/bin/bash

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    # Install homebrew if not installed
    if ! command -v brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    # Update package lists
    sudo apt-get update
else
    echo "Unsupported operating system"
    exit 1
fi

# Function to install packages based on OS
install_package() {
    package_name=$1
    if [[ $OS == "macos" ]]; then
        brew install $package_name
    else
        # Special handling for neovim on Ubuntu
        if [[ $package_name == "neovim" ]]; then
            echo "Installing Neovim stable version..."
            curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
            sudo rm -rf /opt/nvim
            sudo tar -C /opt -xzf nvim-linux64.tar.gz
            sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
            rm nvim-linux64.tar.gz
        else
            sudo apt-get install -y $package_name
        fi
    fi
}

# Install common packages
echo "Installing common packages..."
common_packages=(
    "stow"
    "tmux"
    "neovim"
    "fzf"
    "ripgrep"
    "gnupg"
    "htop"
    "xclip"
    "unzip"
)

for package in "${common_packages[@]}"; do
    echo "Installing $package..."
    install_package $package
done

# Install tmux-mem-cpu-load on Ubuntu
if [[ $OS == "linux" ]]; then
    echo "Installing tmux-mem-cpu-load dependencies..."
    sudo apt-get install -y cmake gcc build-essential
    git clone https://github.com/thewtex/tmux-mem-cpu-load.git
    cd tmux-mem-cpu-load
    cmake .
    make
    sudo make install
    cd ..
    rm -rf tmux-mem-cpu-load
fi

# Install Keybase on Ubuntu
if [[ $OS == "linux" ]]; then
    echo "Installing Keybase..."
    curl --remote-name https://prerelease.keybase.io/keybase_amd64.deb
    sudo apt install -y ./keybase_amd64.deb
    run_keybase
    rm keybase_amd64.deb
fi

# Install nvm
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Setup fonts directory
if [[ $OS == "macos" ]]; then
    FONT_DIR="$HOME/Library/Fonts"
else
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
fi

# Make ~/.local/bin executable
mkdir -p "$HOME/.local/bin"
chmod +x "$HOME/.local/bin"/*

# Import Keybase GPG keys
echo "Importing Keybase GPG keys..."
keybase pgp export -s | gpg --import

# Install zsh and Oh My Zsh BEFORE stowing (but in unattended mode)
install_package "zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    # Remove any existing .zshrc to avoid the overwrite prompt
    rm -f "$HOME/.zshrc"
    # Install Oh My Zsh in unattended mode to prevent shell spawn
    # KEEP_ZSHRC=yes would keep existing .zshrc, but we want the template first
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Remove Oh My Zsh's default .zshrc and stow our custom dotfiles
echo "Stowing dotfiles..."
for dir in */; do
    if [ -d "$dir" ]; then
        stow -v "$dir"
    fi
done

# Change default shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to zsh..."
    chsh -s $(which zsh)
fi

echo "Installation complete!"
echo "Please note:"
echo "1. You need to manually install your preferred Nerd Font"
echo "2. Remember to configure your terminal to use the installed Nerd Font"
echo "3. Make sure to trust the pgp key"
echo "gpg --edit-key 613BED3B035FB1AD0CB1A1063C50DE7686FB9E60
gpg> fpr        # double-check the fingerprint matches exactly
gpg> trust
  (choose 5 = I trust ultimately)
gpg> save
"
