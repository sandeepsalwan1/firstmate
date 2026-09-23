#!/usr/bin/env bash
# drive.sh <label> <tree-root> <path-prefix-or-empty> [VAR=value ...]
set -u
LAB=$(cat /tmp/fm-dispatch-live.path)
label=$1 tree=$2 prefix=$3; shift 3
: > "$LAB/calls"
KEY=$(. "$tree/bin/fm-env-lib.sh"; fmx_env_get TYPESAFE_API_KEY "$HOME/firstmate/.env")
[ -n "$KEY" ] || { echo "no key"; exit 1; }
P=$PATH; [ -n "$prefix" ] && P="$prefix:$PATH"; [ "$prefix" = NOQA ] && P=/opt/homebrew/bin:/usr/bin:/bin
out=$(env "$@" PATH="$P" FM_HOME="$LAB/home" TYPESAFE_API_KEY="$KEY" "$tree/bin/fm-dispatch-resolve.sh" "$LAB/brief.md" --project demo 2>"$LAB/stderr"); code=$?
{
  echo "=== $label"
  echo "\$ ${*:+$* }PATH=${prefix:+$prefix:}\$PATH FM_HOME=\$LAB/home TYPESAFE_API_KEY=<from ~/firstmate/.env> $(basename "$(dirname "$tree")")/$(basename "$tree")/bin/fm-dispatch-resolve.sh brief.md --project demo"
  echo "exit: $code"
  echo "quota-axi calls: $(wc -l < "$LAB/calls" | tr -d ' ') [$(tr '\n' ';' < "$LAB/calls")]"
  echo "--- stdout"; printf '%s\n' "$out"
  echo "--- stderr"; cat "$LAB/stderr"
  echo
} | tee -a "$LAB/transcript.txt"
