#!/bin/bash

# Ambil perubahan staged saja dan batasi ukuran (penting untuk laptop kecil)
DIFF=$(git diff --cached --unified=0 | head -n 300)

# Jika tidak ada perubahan
if [ -z "$DIFF" ]; then
  echo "Tidak ada perubahan untuk di-commit."
  exit 0
fi

# Prompt dibuat seperti instruksi internal tim dev (bukan AI)
PROMPT="Generate a realistic git commit message.

Context:
The following is a git diff from a real project.

Rules:
- 1 line only
- max 72 characters
- lowercase
- no quotes
- no explanation
- no prefixes like 'here is the commit'
- write like an experienced developer
- use: feat, fix, refactor, chore, docs, style, perf, or test

Git diff:
$DIFF

Commit message:"

# Escape karakter agar JSON tidak rusak
ESCAPED_PROMPT=$(printf '%s' "$PROMPT" | sed 's/"/\\"/g')

# Kirim ke Ollama tinyllama
RAW=$(curl -s http://localhost:11434/api/generate -d "{
  \"model\": \"tinyllama\",
  \"prompt\": \"$ESCAPED_PROMPT\",
  \"stream\": false,
  \"options\": {
    \"temperature\": 0.2,
    \"num_predict\": 60
  }
}")

MSG=$(echo "$RAW" | jq -r '.response')

# Bersihkan output (kadang model nambah kata)
MSG=$(echo "$MSG" | head -n 1 | sed 's/Commit message://g' | sed 's/^ *//;s/ *$//')

# fallback jika model gagal
if [ -z "$MSG" ] || [ ${#MSG} -lt 5 ]; then
  MSG="chore: update files"
fi

echo "Commit:"
echo "$MSG"

git commit -m "$MSG"
git push origin main
