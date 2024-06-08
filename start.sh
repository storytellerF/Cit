#!/bin/bash

# Function to check if the current directory is a git repository
is_git_repo() {
  git rev-parse --is-inside-work-tree &>/dev/null
}

# Function to check if the current git repository has a remote
has_remote() {
  git remote -v | grep -q 'git'
}

# Function to check if there are uncommitted changes or waiting commits to push
has_changes() {
  [[ -n $(git status --porcelain) || $(git log @{u}..HEAD) ]]
}

# Function to print log with color
print_log() {
  local color=$1
  local message=$2
  case $color in
  green)
    printf "\033[0;32m%s\033[0m\n" "$message"
    ;;
  red)
    printf "\033[0;31m%s\033[0m\n" "$message"
    ;;
  blue)
    printf "\033[0;34m%s\033[0m\n" "$message"
    ;;
  purple)
    printf "\033[0;35m%s\033[0m\n" "$message"
    ;;
  pink)
    printf "\033[0;36m%s\033[0m\n" "$message"
    ;;
  *)
    printf "%s\n" "$message"
    ;;
  esac
}

# Function to process the current directory
process_directory() {
  local current_dir=$(pwd)
  if is_git_repo; then
    print_log black "Processing directory: $current_dir (Git Repository)"
    if has_remote; then
      print_log pink "Fetching changes in $current_dir..."
      git fetch &>/dev/null
      if git status -uno | grep -q 'Your branch is behind'; then
        if has_changes; then
          print_log red "Cannot fast-forward in $current_dir"
        else
          print_log green "Fast-forwarding in $current_dir"
          git pull --rebase &>/dev/null
        fi
      else
        if has_changes; then
          print_log blue "There are uncommitted changes or waiting commits to push in $current_dir"
        fi
      fi
    else
      print_log purple "No remote configured in $current_dir"
    fi
    return 0
  else
    # print_log black "Processing directory: $current_dir"
    return 1
  fi
}

# Function to recursively traverse directories
traverse_directories() {
  find . -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' dir; do
    cd "$dir" || continue
    process_directory
    if [ $? -eq 1 ]; then
      traverse_directories
    fi
    cd ..
  done
}

# Start traversing from the current directory
traverse_directories
