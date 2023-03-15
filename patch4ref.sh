#!/bin/sh
# patch4ref: apply patches based on the GIT_REF environment variable
# shellcheck disable=SC2317
SELF="$(basename "$0" ".sh")"
set -eu

warn() {
  printf '%s %s %s\n' "$(date '+%FT%T%z')" "$SELF" "$*" >&2
}

die() {
  warn "FATAL:" "$@"
  exit 1
}

usage() {
  printf '%s\n' \
    "Usage: $0 [-h|--help] [--strict] [--git-ref ref]" \
    "" \
    "The program evaluates the GIT_REF environment variable" \
    "(or the \"--git-ref GIT_REF\" cli argument). For the given GIT_REF," \
    "this program applies patches to the source code to make the container" \
    "work (or work better). The GIT_REF can be in any of these formats:" \
    "" \
    "* refs/tags/v2.12.1" \
    "* 2.12.1" \
    "* v2.12.1" \
    "* v2.12" \
    "* v2" \
    "" \
    "If given the --strict flag, the program will exit non-zero if no patch" \
    "was found for the given git ref." \
    "" \
    "$*"

  [ -n "$*" ] && exit 1
  exit 0
}

main() {
  STRICT="${STRICT:-0}"

  while [ $# -gt 0 ]; do
    arg="$1" # shift at end of loop; if you break inside the loop, shift first
    case "$arg" in
      -h|--help)
        usage
        ;;

      --strict)
        STRICT=1
        ;;
      
      --git-ref)
        shift || die "--git-ref requires an argument"
        GIT_REF="$1"
        ;;

      *)
        usage "Unknown argument ${arg}"
        ;;
    esac
    shift || break
  done

  if [ -z "${GIT_REF:-}" ]; then
    die "GIT_REF is required to be set in the environment" \
      "(or specified as a CLI-argument)"
  fi

  semver3="${GIT_REF##*/}"   # major.minor.patch
  semver2="${semver3%.*}"    # major.minor
  semver1="${semver3%.*.*}"  # major

  for v in "$semver3" "$semver2" "$semver1"; do
    patch="patches/${v}.sh"
    if [ -f "$patch" ]; then
      warn "applying patch ${patch} for ref ${GIT_REF}"
      /bin/sh -c "${patch}" || die "Failed running patch file"
      warn "done"
      exit 0
    fi
  done

  status="no patch was found for ref \"${GIT_REF}\""
  if [ "$STRICT" != "0" ]; then
    die "strict mode: ${status}"
  fi
  warn "WARNING: ${status}"
  exit 0
}

main "$@"; exit
