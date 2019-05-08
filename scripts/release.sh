#!/usr/bin/env bash

# TODO:
# - Ensure root directory.

set -eo pipefail

cd "${BASH_SOURCE%/*}/.."

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

info() {
  echo "===>" "$@"
}

print_usage() {
  cat <<EOF
Usage: ${0##*/}
       ${0##*/} -h
Creates a release.

This performs the following steps:
1. Bumps the version number in package.json
2. Finalizes the release in CHANGELOG.md
3. Creates a git tag

OPTIONS
EOF
  sed -n '/^[[:space:]]*###/ s//   /p' "$BASH_SOURCE"

  cat <<EOF

EXIT CODES:
- 0: Success
- 1: General error
- 2: Usage error
- 3: Unsupported release type
- 4: No release detected
EOF
}

while getopts ":h" opt; do
  case "$opt" in
    ### -h	Print this help.
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

info "Determining the release type..."
release_type="$(sed -n '/## \[Unreleased\] \[\(.*\)\]/ s//\1/p' CHANGELOG.md)"
case "$release_type" in
  major | minor | patch | premajor | preminor | prepatch | prerelease | from-git)
    : # valid; do nothing
    ;;
  '')
    die -c 4 "Could not detect potential release in the CHANGELOG."
    ;;
  *)
    die -c 3 "Unsupported release type: ${release_type}."
    ;;
esac

info "Bumping version in package.json..."
new_version="$(npm version "$release_type" --no-git-tag-version)"
info "New version: ${new_version}"

info "Updating changelog..."
ed -s CHANGELOG.md <<EOF
H
/\[Unreleased\].*/ s//[${new_version#v}] - $(date +%F)/
w
q
EOF

info "Committing changes..."
git commit -m "Bump to version ${new_version}" package.json CHANGELOG.md

info "Tagging commit..."
tag_name="${new_version}"
ed -s CHANGELOG.md <<<$'1;/^## \\[/;//-p' | sed -e 's/^##* *//' -e $'1a\\\n\\\n' |
git tag -a "$tag_name" -F -

info "Pushing..."
git push --no-verify origin HEAD "$tag_name"

info "Done."
