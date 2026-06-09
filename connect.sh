#!/usr/bin/env bash
# Securely connect the Redo marketing skills to your account.
#
# Saves your Redo merchant session JWT to ~/.redo/jwt (owner-only) so the
# skills can read it at runtime. The token is entered here in your own
# terminal with hidden input — it never gets pasted into a Claude
# conversation, and never lands in a chat transcript or your shell history.
#
# Usage:  ./connect.sh
set -euo pipefail

mkdir -p ~/.redo
chmod 700 ~/.redo

printf 'Paste your Redo session JWT (input is hidden), then press Enter: '
IFS= read -rs TOKEN
printf '\n'

if [ -z "${TOKEN:-}" ]; then
  echo "No token entered — nothing saved." >&2
  exit 1
fi
case "$TOKEN" in
  eyJ*) : ;;
  *) echo "That doesn't look like a JWT (it should start with 'eyJ') — nothing saved." >&2; exit 1 ;;
esac

( umask 077; printf '%s' "$TOKEN" > ~/.redo/jwt )
chmod 600 ~/.redo/jwt
echo "Saved to ~/.redo/jwt (owner-only). The skills read it from there."

# Confirmation only — decodes the public claims, never prints the token.
payload=$(cut -d. -f2 ~/.redo/jwt | base64 -d 2>/dev/null || true)
if [ -n "$payload" ] && command -v jq >/dev/null 2>&1; then
  aud=$(printf '%s' "$payload" | jq -r '.aud // empty' 2>/dev/null || true)
  exp=$(printf '%s' "$payload" | jq -r '.exp // empty' 2>/dev/null || true)
  [ -n "$aud" ] && echo "  team:    $aud"
  if [ -n "$exp" ]; then
    if date -r "$exp" >/dev/null 2>&1; then
      echo "  expires: $(date -r "$exp")"
    else
      echo "  expires (unix): $exp"
    fi
  fi
fi
