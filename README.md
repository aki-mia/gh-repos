# gh-repos - GitHub Repository Filter Script

## 📌 Overview

`gh-repos` is a shell script that enhances the `gh` CLI to allow users to filter and list repositories efficiently. Users can:

- List repositories they own
- List repositories under a specific organization
- Filter repositories by team (if applicable)
- Display repository metadata in a well-structured format
- Highlight repositories with open pull requests assigned to the user
- Optionally open selected repositories in a browser

## 🚀 Installation

### Prerequisites

Ensure you have the following tools installed:

🔍 List of Required Commands

| Command      | Description                                 | Required Package(s)                                                   |
| ------------ | ------------------------------------------- | --------------------------------------------------------------------- |
| `gh`       | GitHub CLI                                  | `gh`                                                                |
| `fzf`      | Interactive selection tool                  | `fzf`                                                               |
| `awk`      | String processing (truncation)              | `gawk` (GNU Awk) or `awk`                                         |
| `sort`     | Sorting repositories by update date (desc)  | `coreutils` (for macOS)                                             |
| `column`   | Formatting output into aligned columns      | `util-linux` (Linux), `bsdmainutils` (Ubuntu), `column` (macOS) |
| `sed`      | Removes alias from config files (uninstall) | `sed`                                                               |
| `open`     | Opens repository in browser (macOS)         | Built-in on macOS                                                     |
| `xdg-open` | Opens repository in browser (Linux)         | `xdg-utils` (Linux)                                                 |

#### Install with Homebrew (macOS/Linux)

```sh
brew install gh fzf gawk coreutils
```

#### Install with apt (Debian/Ubuntu)

```sh
sudo apt update && sudo apt install gh fzf gawk bsdmainutils xdg-utils
```

#### Install with yum (RHEL/CentOS)

```sh
sudo yum install gh fzf gawk util-linux xdg-utils
```

### Install `gh-repos` with Homebrew(Not Provided now.)

You can install `gh-repos` directly using Homebrew:

```sh
brew tap aki-mia/gh-repos
brew install gh-repos
```

### Script Installation (Manual)

1. Clone this repository:
   ```sh
   git clone https://github.com/aki-mia/gh-repos.git
   cd gh-repos
   ```
2. Add the script to your `.zshrc` or `.bashrc`:
   ```sh
   echo 'source /path/to/gh-repos.zsh' >> ~/.zshrc
   echo 'alias gh-repos="gh_repos"' >> ~/.zshrc
   source ~/.zshrc
   ```

### One-Liner Installation

To install everything automatically (for macOS/Linux), run:

```sh
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/aki-mia/gh-repos/main/install.sh)"
```

## 🔧 Usage

Run the command:

```sh
gh-repos
```

Then:

1. Choose between **Organization Repositories** or **My Personal Repositories**.
2. Select an **Organization**.
3. If teams exist, select a **Team** (or list all repositories in the organization).
4. View the structured output sorted by the last updated date (most recent first).
5. Repositories with open pull requests assigned to you are pinned to the top with a `📌 PR` label.

### Example Output

```
✅ Selected Organization: ExampleOrg

NAME                                              | INFO               | UPDATED
-------------------------------------------------------------------------------------
ExampleOrg/example-repo                    | private            | Mar 24, 2023
ExampleOrg/tools-repo                             | public fork        | Apr 18, 2023
```

### Options

| Option                | Description                                                                                                                                                                                                                                                                                                                      |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-l, --limit <num>` | Set the maximum number of repositories to fetch (default: 100)<br />Note: Only the first `<num>` repositories returned by the GitHub API are processed.<br />This means that if there are additional repositories with more recent updates beyond this limit, they will not be displayed. Increase the limit to include them. |
| `-o, --open`        | Enable selection of a repository to open in the browser                                                                                                                                                                                                                                                                          |
| `-p, --check-pr`    | Only display repositories with PRs assigned to you.<br />If none exist, a message is shown.                                                                                                                                                                                                                                      |
| `-h, --help`        | Show this help message                                                                                                                                                                                                                                                                                                           |

### Open a Repository in Browser

By default, `gh-repos` only displays the repositories. If you want to **select a repository and open it in a browser**, use the `--open` option:

```sh
gh-repos --open
```

This will prompt you to choose a repository from the list using `fzf`, and then open it in your default web browser.

### Customize the Repository Fetch Limit

By default, `gh-repos` fetches up to **100 repositories**. You can modify this limit using the `--limit` option:

```sh
gh-repos --limit 200
```

This fetches up to **200 repositories** instead.


## ❌ Uninstalling `gh-repos`


If you installed it manually, remove it by:

```sh
rm -rf ~/.gh-repos
sed -i '/gh-repos/d' ~/.zshrc ~/.bashrc
source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null
```


## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Contributions are welcome! Feel free to submit pull requests or issues. 🎉
