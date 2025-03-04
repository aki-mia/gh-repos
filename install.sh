#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 Installing MyRepos...${NC}"

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
    brew install gh fzf
elif [[ "$OS_TYPE" == "Linux" ]]; then
    if command -v apt > /dev/null; then
        echo -e "${YELLOW}Installing dependencies using apt...${NC}"
        sudo apt update && sudo apt install -y gh fzf
    elif command -v yum > /dev/null; then
        echo -e "${YELLOW}Installing dependencies using yum...${NC}"
        sudo yum install -y gh fzf
    else
        echo -e "${RED}Unsupported Linux distribution. Please install gh and fzf manually.${NC}"
        exit 1
    fi
else
    echo -e "${RED}Unsupported OS. Please install gh and fzf manually.${NC}"
    exit 1
fi

# Clone the repository and set up the script
REPO_DIR="$HOME/.myrepos"
if [ -d "$REPO_DIR" ]; then
    echo -e "${YELLOW}Updating existing MyRepos installation...${NC}"
    cd "$REPO_DIR" && git pull
else
    echo -e "${YELLOW}Cloning MyRepos repository...${NC}"
    git clone https://github.com/yourusername/myrepos.git "$REPO_DIR"
fi

# Add to shell configuration
echo -e "${YELLOW}Adding MyRepos to shell configuration...${NC}"
SHELL_CONFIG="$HOME/.zshrc"
if [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if ! grep -q "source $REPO_DIR/myrepos.zsh" "$SHELL_CONFIG"; then
    echo "source $REPO_DIR/myrepos.zsh" >> "$SHELL_CONFIG"
fi

source "$SHELL_CONFIG"

echo -e "${GREEN}✅ Installation complete! Run 'myrepos' to start.${NC}"
