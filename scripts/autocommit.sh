#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to find the root directory of a Git repository
#
# This function takes an optional directory path and depth as input and recursively searches for the root directory of a Git repository.
# If no directory path is provided, the current working directory is used as the starting point.
# If no depth is provided, the default maximum depth of 5 is used.
#
# Options:
#   -h, --help        Display the help message and exit
#   -d, --directory   Specify the directory to search for the root directory (default: current working directory)
#   -i, --depth       Specify the current depth of the search (default: 0)
#   -m, --max-depth   Specify the maximum depth of the search (default: 5)
#
# Returns:
#   The absolute path of the root directory if found, or an error message if the root directory is not found.
#
# Example usage:
#   find_git_root                  # Search for the root directory starting from the current working directory with default options
#   find_git_root -d /path/to/dir  # Search for the root directory starting from the specified directory with default options
#   find_git_root -d /path/to/dir -m 10  # Search for the root directory starting from the specified directory with a maximum depth of 10
#
find_git_root() {
  local DIR="${1:-"$(pwd)"}"
  local DEPTH=${2:-0}
  local MAX_DEPTH=5

  show_help() {
    cat << EOF
Usage: ${0##*/} [OPTIONS]...

This is a script to do something useful.

Options:
    -h, --help        Display this help and exit
    -d, --directory   Directory to search for files
    -i, --depth       Current depth of the search
    -m, --max-depth   Maximum depth of the search
EOF
  }

  # parse options using bash built-in getopts
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      -h | --help)
        show_help
        exit 0
        ;;
      -d | --directory)
        DIR="$2"
        shift
        shift
        ;;
      -i | --depth)
        DEPTH="$2"
        shift
        shift
        ;;
      -m | --max-depth)
        MAX_DEPTH="$2"
        shift
        shift
        ;;
      *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
  done

  # Check if depth is greater than max depth
  if [[ $DEPTH -gt $MAX_DEPTH ]]; then
    echo "Error: Max depth reached."
    return 1
  fi
  # Check if the directory exists
  [[ ! -d "$DIR" ]] && echo "Error: Not a directory ($DIR)" && return 1

  # Get the absolute path of the directory
  DIR="$(realpath "$DIR")"

  # Check if the current directory is the root directory
  if [[ "$DIR" == "/" ]]; then
    echo "Git root not found."
    return 1
  fi

  # Check if the current directory contains a .git directory
  if [[ -d "$DIR/.git" ]]; then
    echo "$DIR"
  else
    # Recursively call this function with the parent directory
    find_git_root "$(realpath "$(dirname "$DIR")")" $((CNT + 1))
  fi
}

# Function to update a git repository with the current Unix timestamp as the commit message.
# The function takes an optional argument, which is the directory path of the git repository.
# If no argument is provided, it will search for the git root directory starting from the current directory.

# Parameters:
#   $1 (optional) - The directory path of the git repository. If not provided, it will search for the git root directory.
# Returns:
#   None
update_git() {
  local DIR=${1:-$(find_git_root)} # Store the current directory

  # Check if the current directory is a git repository
  if git rev-parse --git-dir > /dev/null 2>&1; then
    git add .                   # Stage all changes
    git commit -m "$(date +%s)" # Commit with Unix timestamp as message
    git push                    # Push changes to remote repository
    echo "Git repository in $DIR updated successfully."
  else
    echo "Error: $DIR is not a git repository."
    exit 1
  fi
}

main() {
  # make both find_git_root and update_git functions available to the script
  export -f find_git_root
  export -f update_git

  local -A SUBCOMMANDS
  SUBCOMMANDS[find]="find_git_root"
  SUBCOMMANDS[commit]="update_git"
  SUBCOMMANDS[help]="show_help"

  show_help() {
    cat << EOF
Usage: autocommit [SUBCOMMAND] [OPTIONS]...

Subcommands:
    find    Find the root directory of a Git repository
    commit  Update a Git repository with the current Unix timestamp as the commit message
    help    Display this help and exit

Find:
    -d, --directory   Directory to search for files
    -m, --max-depth   Maximum depth of the search
    -h, --help        Display this help and exit

Commit:
    -d, --directory   Directory to search for the root directory. Defaults to find the root directory of the current working directory.
    -h, --help        Display this help and exit

Example usage:
    autocommit find -d /path/to/dir -m 10
    autocommit commit -d /path/to/dir

EOF
  }

  # Check if the subcommand is valid
  if [[ -n $1 && ${SUBCOMMANDS[$1]} ]]; then
    # Call the function associated with the subcommand
    ${SUBCOMMANDS[$1]} "${@:2}"
  else
    show_help
    exit 1
  fi
}

# Call the main function with all the arguments
main "$@"
return $?
