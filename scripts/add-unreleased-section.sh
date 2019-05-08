#!/usr/bin/env bash

set -eo pipefail

die() {
  local exit_code=1
  local OPTIND=1
  local opt

  while getopts "c:" opt; do
    case "$opt" in
      c)
        exit_code="$OPTARG"
        ;;
    esac
  done

  shift $((OPTIND - 1))

  echo "ERROR:" "$@" >&2
  exit $exit_code
}

print_usage() {
  cat <<EOF
Usage: ${0##*/} -h

Adds an unreleased section to the CHANGELOG.md file.

OPTIONS
EOF
  sed -n '/^[[:space:]]*##:/ s//   /p' "$BASH_SOURCE"
}

while getopts :h opt; do
  case "$opt" in
    ##: -h	Show this help
    h)
      print_usage
      exit 0
      ;;
    \?)
      die -c 2 "Invalid option: -${OPTARG}"
      ;;
  esac
done

shift $((OPTIND - 1))

cd "${BASH_SOURCE%/*}/.."

package="$1"
changelog="CHANGELOG.md"

[[ -f "$changelog" ]] || die "Changelog for ${package} not found."

ed -s "$changelog" <<'EOF'
1;/^## /i
## [Unreleased] [major|minor|patch]
### Changed
- <Describe changes>

### Removed
- <Describe removals>

### Added
- <Describe additions>

### Fixed
- <Describe fixes>

### Deprecated
- <Describe deprecations>

### Security
- <Describe security fixes>

.
w
q
EOF
