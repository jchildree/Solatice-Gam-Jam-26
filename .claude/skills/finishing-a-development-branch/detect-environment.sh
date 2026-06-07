#!/bin/bash
if git remote -v 2>/dev/null | grep -q "github.com"; then
  echo "github"
else
  echo "local"
fi
