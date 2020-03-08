#!/bin/bash

gpg --import duplicity.pubkey
echo "$( \
  gpg --list-keys --fingerprint \
  | grep C68E4F18 -A 1 | tail -1 \
  | tr -d '[:space:]' | awk 'BEGIN { FS = "=" } ; { print $2 }' \
):6:" | gpg --import-ownertrust
