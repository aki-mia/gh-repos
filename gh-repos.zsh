#!/bin/bash

# 色設定
bold=$(tput bold)
underline=$(tput smul)
reset=$(tput sgr0)
cyan=$(tput setaf 6)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
red=$(tput setaf 1)
blue=$(tput setaf 4)

# 最大カラム幅設定
NAME_MAX=50
INFO_MAX=20
UPDATED_MAX=20

# 文字列を省略する関数
truncate_string() {
  echo "$1" | awk -v max="$2" '{ if (length($0) > max) print substr($0, 1, max) "..."; else print $0 }'
}

# 相対時間を計算する関数（macOS & Linux 両対応）
relative_time() {
  local timestamp="$1"

  # `updatedAt` が空なら `unknown` を返す
  if [[ -z "$timestamp" ]]; then
    echo "unknown"
    return
  fi

  local current_time=$(date -u +%s)

  # macOS (BSD date) or Linux (GNU date)
  if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%s" >/dev/null 2>&1; then
    local repo_time=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%s")
  else
    local repo_time=$(date -u -d "$timestamp" +%s 2>/dev/null || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%s")
  fi

  if (( repo_time > current_time )); then
    echo "unknown"
    return
  fi

  local diff=$((current_time - repo_time))

  if ((diff < 60)); then
    echo "just now"
  elif ((diff < 3600)); then
    echo "$((diff / 60)) min ago"
  elif ((diff < 86400)); then
    echo "$((diff / 3600)) hours ago"
  elif ((diff < 604800)); then
    echo "$((diff / 86400)) days ago"
  else
    date -u -d @"$repo_time" "+%b %d, %Y" 2>/dev/null || date -u -r "$repo_time" "+%b %d, %Y"
  fi
}

# INFOに色をつける関数
format_info() {
  local visibility="$1"
  local fork="$2"
  local info=""

  if [[ "$visibility" == "true" ]]; then
    info="${red}private${reset}"
  else
    info="${green}public${reset}"
  fi

  if [[ "$fork" == "true" ]]; then
    info="$info ${yellow}fork${reset}"
  fi

  echo "$info"
}

# GitHub CLI を使って自分のチームのリポジトリ or 自分が作成したリポジトリを取得
gh_my_repos() {
  # 1. モード選択
  SEARCH_MODE=$(echo -e "Organization Repositories\nMy Personal Repositories" | fzf --prompt="Select Mode: " --height=5)

  if [[ "$SEARCH_MODE" == "My Personal Repositories" ]]; then
    echo "${cyan}🔍 自分が作成したリポジトリを検索中...${reset}"

    echo ""
    echo "${bold}${underline}NAME                                              | INFO               | UPDATED${reset}"
    echo "-------------------------------------------------------------------------------------"

    gh repo list --limit 100 --json name,owner,visibility,isFork,updatedAt --jq '.[] | select(.owner.login == "'"$(gh api user --jq .login)"'") | [.owner.login + "/" + .name, .visibility, .isFork, .updatedAt] | @tsv' | while IFS=$'\t' read -r name visibility fork updatedAt; do
      formatted_info=$(format_info "$visibility" "$fork")
      relative_time_str=$(relative_time "$updatedAt")
      printf "%-${NAME_MAX}s | %-${INFO_MAX}s | %-${UPDATED_MAX}s\n" "$(truncate_string "$name" $NAME_MAX)" "$formatted_info" "$relative_time_str"
    done
    return 0
  fi

  # 2. 所属するオーガニゼーションを選択
  ORG_NAME=$(gh api user/memberships/orgs --jq '.[].organization.login' | fzf --prompt="Select Organization: " --height=10)

  if [[ -z "$ORG_NAME" ]]; then
    echo "${red}❌ オーガニゼーションが選択されませんでした。終了します。${reset}"
    return 1
  fi

  echo "${green}✅ 選択されたオーガニゼーション: $ORG_NAME${reset}"

  # 3. 選択したオーガニゼーション内のチームを取得
  USER_TEAMS=$(gh api /user/teams --jq '.[] | select(.organization.login=="'"$ORG_NAME"'") | .slug')

  if [[ -z "$USER_TEAMS" ]]; then
    echo "${yellow}⚠️ このオーガニゼーションにはチームがありません。全リポジトリを表示します。${reset}"

    echo ""
    echo "${bold}${underline}NAME                                              | INFO               | UPDATED${reset}"
    echo "-------------------------------------------------------------------------------------"

    gh repo list "$ORG_NAME" --limit 100 --json name,owner,visibility,isFork,updatedAt --jq '.[] | [.owner.login + "/" + .name, .visibility, .isFork, .updatedAt] | @tsv' | while IFS=$'\t' read -r name visibility fork updatedAt; do
      formatted_info=$(format_info "$visibility" "$fork")
      relative_time_str=$(relative_time "$updatedAt")
      printf "%-${NAME_MAX}s | %-${INFO_MAX}s | %-${UPDATED_MAX}s\n" "$(truncate_string "$name" $NAME_MAX)" "$formatted_info" "$relative_time_str"
    done
    return 0
  fi

  # 4. チームを選択
  TEAM_SLUG=$(echo "$USER_TEAMS" | fzf --prompt="Select Team: " --height=10)

  if [[ -z "$TEAM_SLUG" ]]; then
    echo "${red}❌ チームが選択されませんでした。終了します。${reset}"
    return 1
  fi

  echo "${green}✅ 選択されたチーム: $ORG_NAME/$TEAM_SLUG${reset}"

  echo ""
  echo "${bold}${underline}NAME                                              | INFO               | UPDATED${reset}"
  echo "-------------------------------------------------------------------------------------"

  # 5. 選択したチームのリポジトリを取得（構造の違いを修正）
  gh api /orgs/"$ORG_NAME"/teams/"$TEAM_SLUG"/repos --jq '.[] | [.full_name, .private, .fork, .updated_at] | @tsv' | while IFS=$'\t' read -r name visibility fork updatedAt; do
    formatted_info=$(format_info "$visibility" "$fork")
    relative_time_str=$(relative_time "$updatedAt")
    printf "%-${NAME_MAX}s | %-${INFO_MAX}s | %-${UPDATED_MAX}s\n" "$(truncate_string "$name" $NAME_MAX)" "$formatted_info" "$relative_time_str"
  done
}

# ショートカットエイリアス
alias gh-repos="gh_my_repos"