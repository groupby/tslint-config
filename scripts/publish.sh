#!/usr/bin/env bash

set -eo pipefail

tag=latest

die() {
  echo "ERROR:" "$@" >&2
  exit 1
}

print_usage() {
  cat <<EOF
Usage: ${0##*/} [OPTIONS]
       ${0##*/} -h
Publishes the current package to npm based on the version in package.json.

OPTIONS
EOF
  sed -n '/^[[:space:]]*###/ s//   /p' "$BASH_SOURCE"
}

info() {
  echo "===>" "$@"
}

# Change to the root of the repo
cd "${BASH_SOURCE%/*}/.."

while getopts ":t:h" opt; do
  case "$opt" in
    ### -t	The npm tag to release to (defaults to "latest").
    t)
      tag="$OPTARG"
      ;;
    ### -h	Print this help.
    h)
      print_usage
      exit 0
      ;;
    \?)
      die "Invalid option: -${OPTARG}"
      ;;
  esac
done

shift $((OPTIND - 1))

version="$(node -p "require('./package.json').version")"

info "Publishing version ${version} to npm tag ${tag}..."
npm publish --tag "$tag"

tries_left=30

info "Checking npm for published version..."
until npm view ".@${version}" | grep -q .; do
  ((--tries_left)) || die "Published version validation timed out.  (╯°□°)╯︵ ┻━┻"
  info "Version ${version} not yet on npm. Waiting 10 seconds (${tries_left} tries left)..."
  sleep 10
done

info "Done."
