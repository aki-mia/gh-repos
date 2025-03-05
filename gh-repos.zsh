#!/usr/bin/env bash

# Color settings
bold=$(tput bold)
underline=$(tput smul)
reset=$(tput sgr0)
cyan=$(tput setaf 6)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
red=$(tput setaf 1)
blue=$(tput setaf 4)

# Maximum column widths
NAME_MAX=50
INFO_MAX=20
UPDATED_MAX=20

# Function to truncate a string if it exceeds the maximum length
truncate_string() {
  echo "$1" | awk -v max="$2" '{ if (length($0) > max) print substr($0, 1, max) "..."; else print $0 }'
}

# Function to convert a timestamp into a relative time string (supports both macOS and Linux)
relative_time() {
  local timestamp="$1"

  # Return "unknown" if updatedAt is empty
  if [[ -z "$timestamp" ]]; then
    echo "unknown"
    return
  fi

  local current_time
  current_time=$(date -u +%s)

  # Check if BSD (macOS) or GNU (Linux) date is available
  if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%s" >/dev/null 2>&1; then
    local repo_time
    repo_time=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%s")
  else
    local repo_time
    repo_time=$(date -u -d "$timestamp" +%s 2>/dev/null || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%s")
  fi

  # If repository time is in the future, return unknown
  if (( repo_time > current_time )); then
    echo "unknown"
    return
  fi

  local diff=$(( current_time - repo_time ))

  if (( diff < 60 )); then
    echo "just now"
  elif (( diff < 3600 )); then
    echo "$(( diff / 60 )) min ago"
  elif (( diff < 86400 )); then
    echo "$(( diff / 3600 )) hours ago"
  elif (( diff < 604800 )); then
    echo "$(( diff / 86400 )) days ago"
  else
    date -u -d @"$repo_time" "+%b %d, %Y" 2>/dev/null || date -u -r "$repo_time" "+%b %d, %Y"
  fi
}

# Function to convert a timestamp to epoch seconds
get_epoch_time() {
  local timestamp="$1"
  if [[ -z "$timestamp" ]]; then
    echo 0
    return
  fi
  if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%s" >/dev/null 2>&1; then
    date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%s"
  else
    date -u -d "$timestamp" +%s 2>/dev/null || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%s"
  fi
}

# Function to format repository info (coloring visibility and fork status)
format_info() {
  local visibility="$1"
  local fork="$2"
  local info=""

  # Treat "true" or "private" as a private repository
  if [[ "$visibility" == "true" || "$visibility" == "private" ]]; then
    info="${red}private${reset}"
  else
    info="${green}public${reset}"
  fi

  if [[ "$fork" == "true" ]]; then
    info="$info ${yellow}fork${reset}"
  fi

  echo "$info"
}

# Function to display the help message
usage() {
  echo "Usage: gh_my_repos [options]"
  echo ""
  echo "Options:"
  echo "  -l, --limit <num>   Set the maximum number of repositories to fetch (default: 100)"
  echo "  -o, --open          Enable selection of a repository to open in the browser"
  echo "  -p, --check-pr      Only display repositories with PRs assigned to you."
  echo "                      If none exist, a message is shown."
  echo "  -h, --help          Show this help message"
}

# Function to process a single repository record and output a tab-separated line
# Fields: name (with optional PR icon), info, relative time, epoch, PR flag (1 if PR assigned, 0 otherwise)
process_repo_line() {
  local name="$1"
  local visibility="$2"
  local fork="$3"
  local updatedAt="$4"

  local formatted_info
  formatted_info=$(format_info "$visibility" "$fork")
  local relative_time_str
  relative_time_str=$(relative_time "$updatedAt")
  local epoch
  epoch=$(get_epoch_time "$updatedAt")
  local pr_flag=0
  local pr_icon=""

  # If PR check is enabled, filter repositories to only those with PRs assigned to me
  if [[ $check_pr -eq 1 ]]; then
    local pr_result
    pr_result=$(gh pr list --repo "$name" --json 'assignees' --search 'assignee:@me' 2>/dev/null | tr -d '[:space:]')
    if [[ "$pr_result" == "[]" || -z "$pr_result" ]]; then
      return 0
    else
      pr_flag=1
      pr_icon=" 🔔"
    fi
  fi

  echo -e "${name}${pr_icon}\t${formatted_info}\t${relative_time_str}\t${epoch}\t${pr_flag}"
}

# Function to process repository records
# If -p option is enabled, process lines in parallel with a concurrency limit (10)
process_repos() {
  local input="$1"
  if [[ $check_pr -eq 1 ]]; then
    local tmpdir
    tmpdir=$(mktemp -d)
    while IFS= read -r line; do
      (
        IFS=$'\t' read -r name visibility fork updatedAt <<< "$line"
        process_repo_line "$name" "$visibility" "$fork" "$updatedAt" > "$tmpdir/$$.$RANDOM"
      ) &
      while (( $(jobs -r | wc -l) >= 10 )); do
        wait -n
      done
    done <<< "$input"
    wait
    cat "$tmpdir"/*
    rm -rf "$tmpdir"
  else
    while IFS= read -r line; do
      IFS=$'\t' read -r name visibility fork updatedAt <<< "$line"
      process_repo_line "$name" "$visibility" "$fork" "$updatedAt"
    done <<< "$input"
  fi
}

# Main function to fetch and display GitHub repositories
gh_my_repos() {
  local limit=100
  local open_repo=0
  check_pr=0
  my_login=""

  while [[ "$1" != "" ]]; do
    case "$1" in
      -l|--limit)
        shift
        limit="$1"
        ;;
      -o|--open)
        open_repo=1
        ;;
      -p|--check-pr)
        check_pr=1
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        echo -e "${red}Unknown option: $1${reset}"
        usage
        return 1
        ;;
    esac
    shift
  done

  # If PR checking is enabled, get the current user's login (not used here anymore but kept for consistency)
  if [[ $check_pr -eq 1 ]]; then
    my_login=$(gh api user --jq .login)
  fi

  local repos_data=""
  local SEARCH_MODE
  SEARCH_MODE=$(echo -e "Organization Repositories\nMy Personal Repositories" | fzf --prompt="Select Mode: " --height=5)

  if [[ "$SEARCH_MODE" == "My Personal Repositories" ]]; then
    echo -e "${cyan}🔍 Searching for my personal repositories...${reset}"
    local user_login
    user_login=$(gh api user --jq .login)
    repos_data=$(gh repo list --limit "$limit" --json name,owner,visibility,isFork,updatedAt,isPrivate --jq \
      '.[] | select(.owner.login == "'"$user_login"'") | [.owner.login + "/" + .name, .isPrivate, .isFork, .updatedAt] | @tsv')
  else
    local ORG_NAME
    ORG_NAME=$(gh api user/memberships/orgs --jq '.[].organization.login' | fzf --prompt="Select Organization: " --height=10)
    if [[ -z "$ORG_NAME" ]]; then
      echo -e "${red}❌ No organization selected. Exiting.${reset}"
      return 1
    fi

    echo -e "${green}✅ Selected Organization: $ORG_NAME${reset}"

    local USER_TEAMS
    USER_TEAMS=$(gh api /user/teams --jq '.[] | select(.organization.login=="'"$ORG_NAME"'") | .slug')

    if [[ -z "$USER_TEAMS" ]]; then
      echo -e "${yellow}⚠️ No teams found in this organization. Displaying all repositories.${reset}"
      repos_data=$(gh repo list "$ORG_NAME" --limit "$limit" --json name,owner,visibility,isFork,updatedAt,isPrivate --jq \
        '.[] | [.owner.login + "/" + .name, .isPrivate, .isFork, .updatedAt] | @tsv')
    else
      local TEAM_SLUG
      TEAM_SLUG=$(echo "$USER_TEAMS" | fzf --prompt="Select Team: " --height=10)
      if [[ -z "$TEAM_SLUG" ]]; then
        echo -e "${red}❌ No team selected. Exiting.${reset}"
        return 1
      fi
      echo -e "${green}✅ Selected Team: $ORG_NAME/$TEAM_SLUG${reset}"
      repos_data=$(gh api "/orgs/$ORG_NAME/teams/$TEAM_SLUG/repos?per_page=$limit" --jq \
        '.[] | [.full_name, .private, .fork, .updated_at] | @tsv')
      repos_data=$(echo "$repos_data" | head -n "$limit")
    fi
  fi

  local all_repo_lines
  all_repo_lines=$(process_repos "$repos_data")

  # If -p option is enabled, only repositories with PRs assigned to me will be output.
  # If none, show a message.
  if [[ $check_pr -eq 1 && -z "$all_repo_lines" ]]; then
    echo -e "${yellow}No repositories found with PRs assigned to you.${reset}"
    return 0
  fi

  local sorted
  if [[ $check_pr -eq 1 ]]; then
    sorted=$(echo "$all_repo_lines" | sort -t $'\t' -k5,5nr -k4,4nr)
  else
    sorted=$(echo "$all_repo_lines" | sort -t $'\t' -k4,4nr)
  fi

  echo ""
  echo -e "${bold}${underline}NAME                                              | VISIBILITY               | UPDATED${reset}"
  echo "-------------------------------------------------------------------------------------"

  while IFS=$'\t' read -r name formatted_info relative_time_str epoch pr_flag; do
    printf "%-${NAME_MAX}s | %-${INFO_MAX}s | %-${UPDATED_MAX}s\n" "$(truncate_string "$name" $NAME_MAX)" "$formatted_info" "$relative_time_str"
  done <<< "$sorted"

  if [[ $open_repo -eq 1 ]]; then
    local selected_repo
    selected_repo=$(echo "$sorted" | cut -f1 | fzf --prompt="Select repository to open: ")
    if [[ -n "$selected_repo" ]]; then
      echo -e "${green}Opening repository ${selected_repo}${reset}"
      gh repo view "$selected_repo" --web
    fi
  fi
}

# Shortcut alias
alias gh-repos="gh_my_repos"
