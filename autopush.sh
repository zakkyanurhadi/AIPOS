#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =========================
# Get current branch
# =========================
CURRENT_BRANCH=$(git branch --show-current)

# =========================
# Get staged changes
# =========================
echo -e "${BLUE}=== Checking for staged changes... ===${NC}"

DIFF=$(git diff --cached --unified=0 | head -n 100)
FILES=$(git diff --cached --name-only)

if [ -z "$FILES" ]; then
  echo -e "${RED}No staged changes found.${NC}"
  echo -e "${YELLOW}You need to stage files first:${NC}"
  echo "  git add <file>"
  echo "  or"
  echo "  git add ."
  exit 1
fi

echo -e "${GREEN}✓ Found staged changes${NC}"
echo ""

# =========================
# Show what's being committed
# =========================
echo -e "${CYAN}=== Summary of Changes ===${NC}"
echo -e "${YELLOW}Current Branch:${NC} $CURRENT_BRANCH"
echo ""
echo -e "${YELLOW}Files to be committed:${NC}"
echo "$FILES" | while read file; do
  STATUS=$(git diff --cached --name-status "$file" | cut -f1)
  case $STATUS in
    A) COLOR=$GREEN; STATUS_TEXT="Added   ";;
    M) COLOR=$YELLOW; STATUS_TEXT="Modified";;
    D) COLOR=$RED; STATUS_TEXT="Deleted ";;
    R) COLOR=$PURPLE; STATUS_TEXT="Renamed ";;
    C) COLOR=$CYAN; STATUS_TEXT="Copied  ";;
    *) COLOR=$NC; STATUS_TEXT="Unknown ";;
  esac
  echo -e "  ${COLOR}${STATUS_TEXT}${NC} - $file"
done

echo ""
echo -e "${YELLOW}Changes preview:${NC}"
if [ -n "$DIFF" ]; then
  echo "$DIFF" | head -n 30
  if [ $(echo "$DIFF" | wc -l) -gt 30 ]; then
    echo -e "${YELLOW}... (more changes not shown)${NC}"
  fi
else
  echo -e "${YELLOW}(No diff preview available)${NC}"
fi
echo -e "${CYAN}================================${NC}"
echo ""

# =========================
# Get commit message from user
# =========================
echo -e "${BLUE}=== Commit Message ===${NC}"
echo -e "${YELLOW}Recommended format:${NC}"
echo "  feat: add new feature"
echo "  fix: resolve issue"
echo "  refactor: improve code structure"
echo "  chore: maintenance tasks"
echo "  docs: update documentation"
echo "  style: code formatting"
echo "  test: add/update tests"
echo "  perf: performance improvements"
echo ""
echo -e "${YELLOW}Examples:${NC}"
echo "  feat: add user login functionality"
echo "  fix: correct button click handler"
echo "  docs: update API documentation"
echo ""

while true; do
  read -p "Enter commit message: " COMMIT_MSG
  
  # Trim whitespace
  COMMIT_MSG=$(echo "$COMMIT_MSG" | xargs)
  
  if [ -z "$COMMIT_MSG" ]; then
    echo -e "${RED}Commit message cannot be empty.${NC}"
    continue
  fi
  
  # Optional: Validate format (can be removed if not needed)
  if ! echo "$COMMIT_MSG" | grep -E '^(feat|fix|refactor|chore|docs|style|test|perf|build|ci|revert):' >/dev/null; then
    echo -e "${YELLOW}Warning: Commit message doesn't follow conventional format.${NC}"
    echo -e "${YELLOW}Continue anyway? [y/N]: ${NC}\c"
    read -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      continue
    fi
  fi
  
  break
done

# =========================
# Add timestamp (optional)
# =========================
echo -e "\n${YELLOW}Add timestamp to commit message? [y/N]: ${NC}\c"
read -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
  FINAL_MSG="$COMMIT_MSG ($TIMESTAMP)"
else
  FINAL_MSG="$COMMIT_MSG"
fi

# =========================
# Show final confirmation
# =========================
echo -e "\n${PURPLE}=== Final Review ===${NC}"
echo -e "${YELLOW}Branch:${NC} $CURRENT_BRANCH"
echo -e "${YELLOW}Files:${NC}"
echo "$FILES"
echo -e "${YELLOW}Commit message:${NC}"
echo -e "  ${GREEN}$FINAL_MSG${NC}"
echo ""

echo -e "${RED}Proceed with commit? [y/N]: ${NC}\c"
read -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Commit cancelled.${NC}"
  exit 0
fi

# =========================
# Perform the commit
# =========================
echo -e "${BLUE}Committing changes...${NC}"
if git commit -m "$FINAL_MSG"; then
  echo -e "${GREEN}✓ Successfully committed to $CURRENT_BRANCH${NC}"
  echo ""
  
  # =========================
  # Ask about pushing
  # =========================
  echo -e "${CYAN}=== Push to Remote ===${NC}"
  echo "1) Push to origin/$CURRENT_BRANCH"
  echo "2) Push to different branch"
  echo "3) Don't push now"
  echo ""
  
  read -p "Choose option [1-3]: " PUSH_CHOICE
  
  case $PUSH_CHOICE in
    1)
      echo -e "${BLUE}Pushing to origin/$CURRENT_BRANCH...${NC}"
      if git push origin "$CURRENT_BRANCH"; then
        echo -e "${GREEN}✓ Successfully pushed to origin/$CURRENT_BRANCH${NC}"
      else
        echo -e "${RED}✗ Push failed${NC}"
        echo -e "${YELLOW}You can try manually: git push origin $CURRENT_BRANCH${NC}"
      fi
      ;;
      
    2)
      # Show available remote branches
      echo -e "${BLUE}Available remote branches:${NC}"
      git branch -r | head -15
      echo ""
      
      read -p "Enter target branch name (without 'origin/'): " TARGET_BRANCH
      
      if [ -z "$TARGET_BRANCH" ]; then
        echo -e "${RED}No branch specified.${NC}"
        exit 1
      fi
      
      echo -e "${BLUE}Pushing to origin/$TARGET_BRANCH...${NC}"
      
      # Check if branch exists on remote
      if git ls-remote --exit-code --heads origin "$TARGET_BRANCH" >/dev/null 2>&1; then
        # Push to existing branch
        if git push origin "$CURRENT_BRANCH:$TARGET_BRANCH"; then
          echo -e "${GREEN}✓ Successfully pushed to origin/$TARGET_BRANCH${NC}"
        else
          echo -e "${RED}✗ Push failed${NC}"
        fi
      else
        echo -e "${YELLOW}Branch 'origin/$TARGET_BRANCH' doesn't exist.${NC}"
        echo -e "${YELLOW}Create new branch '$TARGET_BRANCH' on remote? [y/N]: ${NC}\c"
        read -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          if git push origin "$CURRENT_BRANCH:refs/heads/$TARGET_BRANCH"; then
            echo -e "${GREEN}✓ Created and pushed to origin/$TARGET_BRANCH${NC}"
          else
            echo -e "${RED}✗ Failed to create branch${NC}"
          fi
        else
          echo -e "${YELLOW}Push cancelled.${NC}"
        fi
      fi
      ;;
      
    3)
      echo -e "${YELLOW}Not pushing now. You can push later with:${NC}"
      echo "  git push origin $CURRENT_BRANCH"
      ;;
      
    *)
      echo -e "${YELLOW}Invalid option. Not pushing.${NC}"
      ;;
  esac
  
  # Show git status after commit
  echo -e "\n${CYAN}=== Current Status ===${NC}"
  git status --short
  
else
  echo -e "${RED}✗ Commit failed${NC}"
  echo -e "${YELLOW}Check for errors above.${NC}"
  exit 1
fi

echo -e "\n${GREEN}✓ Done!${NC}"