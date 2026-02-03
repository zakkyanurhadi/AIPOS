#!/bin/bash

# pesan commit otomatis dengan timestamp
MSG="auto commit $(date '+%Y-%m-%d %H:%M:%S')"

git add .
git commit -m "$MSG"
git push -u origin main
