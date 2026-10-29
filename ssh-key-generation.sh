#!/usr/bin/env bash
set -euo pipefail

KEY="$HOME/.ssh/kubernetes-lab"

if [[ ! -f "$KEY" ]]; then
  ssh-keygen -t ed25519 -f "$KEY" -N "" -C "kubernetes-lab"
fi