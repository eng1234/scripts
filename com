#!/bin/bash
# Add tracked modified files (excluding build artifacts) and commit

git ls-files --modified | grep -vi -e 'ZigbeeStack' -e 'ZigbeeAppCommon' \
    -e 'SecureEFR32Bootloader' | tr -d '\r' | xargs -d '\n' git add
git commit -m "$*"
