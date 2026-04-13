#!/bin/sh

git branch --show-current
echo "Modified:"
git ls-files --modified
echo "......................."
git status | grep -E "\.(c|cpp|h|md)$"

