#!/usr/bin/env bash
# Print the chibi Byanca. Home-manager installs this as `byanca`.
# NO_COLOR, or a locale that is not UTF-8, prints the plain ASCII cat.
set -euo pipefail

art="${BYANCA_ART:-}"
if [ -z "$art" ]; then
  art="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/byanca-chibi.ans"
fi

byanca_utf8() {
  local charmap lang
  charmap="$(locale charmap 2>/dev/null || true)"
  case "$charmap" in
    UTF-8 | utf-8 | UTF8) return 0 ;;
  esac
  lang="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
  case "$lang" in
    *[Uu][Tt][Ff]-8* | *[Uu][Tt][Ff]8*) return 0 ;;
  esac
  return 1
}

if [ -n "${NO_COLOR:-}" ] || ! byanca_utf8; then
  cat <<'EOF'
    /\_/\
   ( o.o )
  <(  ^  )>
   /| V |\
  / |   | \
 (  |   |  )
  \_|___|_/
   /_/ \_\
  wsl/ubuntu-nix  -  crafted by Byanca  nya~
EOF
  exit 0
fi

cat "$art"
printf '\033[38;2;208;208;255m%s\033[0m\n' '>> crafted by Byanca  ฅ^•ﻌ•^ฅ  nya~'
