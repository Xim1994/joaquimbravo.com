#!/usr/bin/env bash
# One-shot deploy of joaquimbravo.com to GitHub Pages
# Run from inside projects/cv-website/

set -euo pipefail

REPO="Xim1994/joaquimbravo.com"
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Working in $DIR"
cd "$DIR"

# 1. Git init (if not already)
if [ ! -d .git ]; then
  echo "==> git init"
  git init -b main
fi

# 2. GitHub auth
if ! gh auth status >/dev/null 2>&1; then
  echo "==> gh auth login (follow the browser prompt)"
  gh auth login -h github.com -p https -w
fi

# 3. Create repo (public). If exists, skip.
if ! gh repo view "$REPO" >/dev/null 2>&1; then
  echo "==> Creating public repo $REPO"
  gh repo create "$REPO" --public --source=. --remote=origin --description "Personal CV at joaquimbravo.com" --disable-wiki
else
  echo "==> Repo exists, ensuring remote origin"
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/${REPO}.git"
fi

# 4. First commit
git add .
if ! git diff --staged --quiet; then
  git commit -m "Initial: personal CV at joaquimbravo.com"
fi

# 5. Push
echo "==> Pushing to main"
git push -u origin main

# 6. Enable GitHub Pages via API
OWNER="${REPO%/*}"
REPO_NAME="${REPO#*/}"
echo "==> Enabling GitHub Pages (main / root)"
gh api -X POST "repos/${OWNER}/${REPO_NAME}/pages" \
  -f "source[branch]=main" -f "source[path]=/" 2>/dev/null || \
  gh api -X PUT "repos/${OWNER}/${REPO_NAME}/pages" \
  -f "source[branch]=main" -f "source[path]=/" 2>/dev/null || \
  echo "   (Pages may already be configured)"

# 7. Set custom domain
echo "==> Setting custom domain joaquimbravo.com"
gh api -X PUT "repos/${OWNER}/${REPO_NAME}/pages" \
  -f "cname=joaquimbravo.com" 2>/dev/null || true

echo ""
echo "==> Done."
echo "    Repo:  https://github.com/${REPO}"
echo "    Pages: https://${OWNER,,}.github.io/${REPO_NAME} (temporary URL)"
echo "    Final: https://joaquimbravo.com  (once DNS propagates)"
