#!/usr/bin/env bash
# =====================================================
# upload.sh  --  16.3-Adapter.Requirement
# Usage: cd "16.3-Adapter.Requirement" && bash upload.sh
# No password needed -- token is embedded.
# =====================================================
set -e

REPO="https://AlexYang:27e891e7135bf90a1dbc8325b167303c39f3ecd9@codeberg.org/AlexYang/Adapter_Andriod2HMOS.git"
BRANCH="alex"
DIR_NAME="16.3-Adapter.Requirement"

echo ""
echo "======================================================"
echo "  Upload : ${DIR_NAME}"
echo "  Target : ${BRANCH} branch"
echo "======================================================"
echo ""

# -- 1. Init git ----------------------------------------
if [ ! -d ".git" ]; then
  echo "[1/5] Initializing git repo..."
  git init
  git remote add origin "${REPO}"
else
  echo "[1/5] Git already initialized"
  git remote set-url origin "${REPO}"
fi

# -- 2. Switch to target branch (local only) ------------
echo "[2/5] Switching to branch '${BRANCH}'..."
git checkout -B "${BRANCH}"

# -- 3. Set user identity --------------------------------
git config user.name  "AlexYang"
git config user.email "alexyang@noreply.codeberg.org"

# -- 4. Stage files (.gitignore excludes intermediates) --
echo "[4/5] Staging files..."
git add .
echo ""
echo "Files to be uploaded (first 60):"
git diff --cached --name-only | head -60
echo ""

# -- 5. Commit & force-push ------------------------------
COUNT=$(git diff --cached --name-only | wc -l | tr -d ' ')
if [ "${COUNT}" = "0" ]; then
  echo "[5/5] No changes to commit."
else
  echo "[5/5] Committing ${COUNT} file(s) and pushing..."
  git commit -m "feat(${DIR_NAME}): upload project source code"
  git push --force origin "${BRANCH}"
fi

echo ""
echo "Done."
echo "View at: https://codeberg.org/AlexYang/Adapter_Andriod2HMOS/src/branch/${BRANCH}"
echo ""
