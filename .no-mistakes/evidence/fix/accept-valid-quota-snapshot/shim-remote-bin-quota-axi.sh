#!/usr/bin/env bash
printf 'dev-new:%s\n' "$*" >> "/tmp/fm-dispatch-live.04Pznk/calls"
exec ssh -o BatchMode=yes -o ConnectTimeout=10 dev-new quota-axi "$@"
