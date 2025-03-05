#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 Installing gh-repos...${NC}"

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Darwin*)  OS_TYPE="macOS" ;;
    Linux*)   OS_TYPE="Linux" ;;
    *)        OS_TYPE="Unknown" ;;
esac

echo -e "${YELLOW}Detected OS: $OS_TYPE${NC}"

# Install dependencies
if [[ "$OS_TYPE" == "macOS" ]]; then
    echo -e "${YELLOW}Installing dependencies using Homebrew...${NC}"
    brew install gh fzf gawk coreutils
elif [[ "$OS_TYPE" == "Linux" ]]; then
    if command -v apt > /dev/null; then
        echo -e "${YELLOW}Installing dependencies using apt...${NC}"
        sudo apt update && sudo apt install gh fzf gawk bsdmainutils xdg-utils
    elif command -v yum > /dev/null; then
        echo -e "${YELLOW}Installing dependencies using yum...${NC}"
        sudo yum install gh fzf gawk util-linux xdg-utils
    else
        echo -e "${RED}Unsupported Linux distribution. Please install gh and fzf manually.${NC}"
        exit 1
    fi
else
    echo -e "${RED}Unsupported OS. Please install gh and fzf manually.${NC}"
fi

# Clone the repository and set up the script
REPO_DIR="$HOME/.gh-repos"
if [ -d "$REPO_DIR" ]; then
    echo -e "${YELLOW}Updating existing gh-repos installation...${NC}"
    cd "$REPO_DIR" && git pull
else
    echo -e "${YELLOW}Cloning gh-repos repository...${NC}"
    git clone https://github.com/aki-mia/gh-repos.git "$REPO_DIR"
fi

# Add to shell configuration
echo -e "${YELLOW}Adding gh-repos to shell configuration...${NC}"
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    SHELL_CONFIG="$HOME/.profile"
fi

if ! grep -q "source $REPO_DIR/gh-repos.zsh" "$SHELL_CONFIG"; then
    echo "source $REPO_DIR/gh-repos.zsh" >> "$SHELL_CONFIG"
fi

source "$SHELL_CONFIG"

echo -e "${GREEN}✅ Installation complete! Restart your terminal and Run 'gh-repos' to start.${NC}"
