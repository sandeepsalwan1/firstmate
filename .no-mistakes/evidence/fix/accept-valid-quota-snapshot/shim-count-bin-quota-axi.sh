#!/usr/bin/env bash
printf '%s\n' "$*" >> "/tmp/fm-dispatch-live.04Pznk/calls"
exec "/Users/salwansa/.local/share/npm/bin/quota-axi" "$@"
