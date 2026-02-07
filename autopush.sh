#!/bin/bash

# ambil perubahan staged (ringkas)
DIFF=$(git diff --cached --unified=0 | head -n 200)

if [ -z "$DIFF" ]; then
  echo "Tidak ada perubahan untuk di-commit."
  exit 0
fi

PROMPT="You are writing a git commit.

Rules:
- one line
- max 60 chars
- start with feat:, fix:, refactor:, chore:, docs:, style:, perf:, or test:
- no explanation

Diff:
$DIFF


Commit:"

# ===== PENTING =====
# gunakan jq untuk membentuk JSON (bukan sed)
JSON=$(jq -n \
  --arg model "tinyllama" \
  --arg prompt "$PROMPT" \
  '{
    model: $model,
    prompt: $prompt,
    stream: false,
    options: {
      temperature: 0.1,
      num_predict: 40
    }
  }')

RAW=$(curl -s http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d "$JSON")

MSG=$(echo "$RAW" | jq -r '.response')

# bersihkan
MSG=$(echo "$MSG" | tr -d '\r' | head -n 1)
MSG=$(echo "$MSG" | sed 's/^ *//;s/ *$//')

if [ -z "$MSG" ] || [ "$MSG" = "null" ]; then
  echo "AI tidak merespon. Cek Ollama."
  exit 1
fi

echo "Commit:"
echo "$MSG"

git commit -m "$MSG"
git push origin main
