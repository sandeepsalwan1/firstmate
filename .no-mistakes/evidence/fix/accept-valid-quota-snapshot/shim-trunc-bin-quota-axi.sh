#!/usr/bin/env bash
printf '%s\n' "$*" >> "/tmp/fm-dispatch-live.04Pznk/calls"
"/Users/salwansa/.local/share/npm/bin/quota-axi" "$@" | head -c 300
exit 1
