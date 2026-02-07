#!/bin/bash

# =========================
# ambil perubahan staged
# =========================
DIFF=$(git diff --cached --unified=0 | head -n 220)

if [ -z "$DIFF" ]; then
  echo "Tidak ada perubahan untuk di-commit."
  exit 0
fi

# =========================
# prompt khusus commit (sangat pendek)
# =========================
PROMPT="Buat pesan git commit 1 baris saja.

Gunakan format:
feat:, fix:, refactor:, chore:, docs:, style:, perf:, atau test:

Tidak boleh ada penjelasan.
Bahasa Indonesia sederhana.

Diff:
$DIFF

commit:"

# =========================
# bentuk JSON valid (anti error Windows)
# =========================
JSON=$(jq -n \
  --arg model "codegemma:2b" \
  --arg prompt "$PROMPT" \
  '{
    model: $model,
    prompt: $prompt,
    stream: false,
   options: {
    temperature: 0.1,
    num_predict: 25,
    top_p: 0.8,
    repeat_penalty: 1.3,
    stop: ["\n"]
}
  }')

# =========================
# kirim ke Ollama
# =========================
RAW=$(curl -s http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d "$JSON")

# =========================
# ambil hasil AI
# =========================
MSG=$(echo "$RAW" | jq -r '.response')

# ambil baris pertama saja
MSG=$(echo "$MSG" | tr -d '\r' | head -n 1)

# potong jika model menulis "commit:"
MSG=$(echo "$MSG" | sed 's/.*commit:[ ]*//I')

# trim spasi
MSG=$(echo "$MSG" | sed 's/^ *//;s/ *$//')

# =========================
# validasi hasil
# =========================
if ! echo "$MSG" | grep -E '^(feat|fix|refactor|chore|docs|style|perf|test):' >/dev/null; then
  MSG="chore: update files"
fi

# =========================
# tambahkan timestamp
# =========================
TIME=$(date "+%Y-%m-%d %H:%M")
FINAL_MSG="$MSG ($TIME)"

echo "Commit:"
echo "$FINAL_MSG"

# =========================
# commit + push
# =========================
git commit -m "$FINAL_MSG"
git push origin main
