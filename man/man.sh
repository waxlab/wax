#!/bin/bash
# Temporary file to read markdown as man

dir=$(dirname $(realpath $0))

cat "$dir/$1.md" | \
  sed 's/^\(\#\{1,2\}\s.*\)/\U&\n\n/g;s/^######\s/###### > /g' | \
  pandoc -s -f markdown_strict -t man | man -l -

