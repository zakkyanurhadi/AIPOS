#!/bin/bash

# =========================
# Get staged changes
# =========================
DIFF=$(git diff --cached --unified=0 | head -n 150)

if [ -z "$DIFF" ]; then
  echo "No changes to commit."
  exit 0
fi

# =========================
# Optimized prompt for codegemma:2b
# =========================
PROMPT="Generate one-line git commit message based on diff.

Required format exactly: [type]: [brief description]

Allowed types: feat, fix, refactor, chore, docs, style, perf, test

Diff:
$DIFF

Message:"

# =========================
# JSON with codegemma:2b settings
# =========================
JSON=$(jq -n \
  --arg model "codegemma:2b" \
  --arg prompt "$PROMPT" \
  '{
    model: $model,
    prompt: $prompt,
    stream: false,
    options: {
      temperature: 0.2,
      num_predict: 60,
      top_p: 0.85,
      repeat_penalty: 1.2,
      top_k: 40
    }
  }')

# =========================
# Send to Ollama
# =========================
RAW=$(curl -s http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d "$JSON")

# =========================
# Extract and clean AI response
# =========================
# Get raw response
MSG=$(echo "$RAW" | jq -r '.response')

# Debug: show raw response
echo "=== AI Raw Response ==="
echo "$MSG"
echo "=== End Raw ==="

# Clean Windows line endings
MSG=$(echo "$MSG" | tr -d '\r')

# Extract commit message - codegemma specific patterns
# Try multiple extraction patterns for codegemma
MSG=$(echo "$MSG" | grep -oE '^(feat|fix|refactor|chore|docs|style|perf|test):[^[:space:]].*' | head -n1)

# Alternative if no match found
if [ -z "$MSG" ]; then
  # Look for pattern anywhere in response
  MSG=$(echo "$MSG" | grep -oE '(feat|fix|refactor|chore|docs|style|perf|test):[^"]+' | head -n1)
fi

# Remove quotes and extra spaces
MSG=$(echo "$MSG" | sed 's/"//g;s/\.$//;s/^ *//;s/ *$//')

# =========================
# Validate and generate fallback
# =========================
if [ -z "$MSG" ] || ! echo "$MSG" | grep -E '^(feat|fix|refactor|chore|docs|style|perf|test):' >/dev/null; then
  # Generate context-aware fallback message
  echo "AI didn't return valid format. Generating fallback..."
  
  # Analyze diff for better fallback
  if echo "$DIFF" | grep -q -i "add\|create\|new\|implement"; then
    MSG="feat: add new feature"
  elif echo "$DIFF" | grep -q -i "fix\|bug\|error\|issue"; then
    MSG="fix: resolve issue"
  elif echo "$DIFF" | grep -q -i "update\|change\|modify\|adjust"; then
    MSG="refactor: update code"
  elif echo "$DIFF" | grep -q -i "remove\|delete\|clean"; then
    MSG="chore: remove unused code"
  elif echo "$DIFF" | grep -q -i "doc\|readme\|comment"; then
    MSG="docs: update documentation"
  elif echo "$DIFF" | grep -q -i "style\|format\|indent\|whitespace"; then
    MSG="style: format code"
  else
    # Count file types for better message
    FILES=$(git diff --cached --name-only | head -5)
    if echo "$FILES" | grep -q "\.js$\|\.ts$\|\.py$\|\.java$"; then
      MSG="refactor: update source files"
    elif echo "$FILES" | grep -q "\.md$\|\.txt$\|\.rst$"; then
      MSG="docs: update documentation"
    elif echo "$FILES" | grep -q "\.json$\|\.yml$\|\.yaml$\|\.toml$"; then
      MSG="chore: update configuration"
    else
      MSG="chore: update files"
    fi
  fi
fi

# Ensure it's a single line
MSG=$(echo "$MSG" | head -n1 | xargs)

# =========================
# Add timestamp
# =========================
TIME=$(date "+%Y-%m-%d %H:%M")
FINAL_MSG="$MSG ($TIME)"

echo ""
echo "Commit message:"
echo "$FINAL_MSG"

# =========================
# Confirm before committing
# =========================
read -p "Commit with this message? [y/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  git commit -m "$FINAL_MSG"
  echo "Committed successfully."
  
  # Optional: push automatically
  read -p "Push to origin/main? [y/N] " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin main
  fi
else
  echo "Commit cancelled."
  exit 1
fi