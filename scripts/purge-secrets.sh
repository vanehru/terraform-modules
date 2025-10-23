#!/usr/bin/env bash
set -euo pipefail

# purge-secrets.sh
# Safe helper script to remove sensitive files/strings from git history.
# Requires: git-filter-repo (recommended) OR BFG Repo-Cleaner.

echo "This script will prepare commands and guidance to remove secrets from git history."
echo "It will NOT run destructive operations automatically. Read and run the recommended commands yourself."

cat <<'DOC'
Recommended workflow (git-filter-repo):

# 1) Backup your repository
git clone --mirror <repo_url> repo-mirror-backup.git

# 2) Use git-filter-repo to remove files/paths (example: remove terraform.tfvars and demo tfvars):
git clone <repo_url> repo-clean
cd repo-clean
# Example: remove specific files by path
git filter-repo --invert-paths --path demo-03/terraform.tfvars --path demo-03/tfvars/basic_password.tfvars

# 3) Inspect the repo, run tests, then force-push to remote (coordinate with team):
git remote add origin-clean <repo_url>
git push --force --all origin-clean
git push --force --tags origin-clean

If you cannot use git-filter-repo, use BFG Repo-Cleaner for large repos:

# With BFG, create a text file with strings or paths to delete, e.g. secrets.txt
# secrets.txt content example:
# demo-03/terraform.tfvars
# demo-03/tfvars/basic_password.tfvars

# Then run:
# java -jar bfg.jar --delete-files secrets.txt repo-mirror.git
# cd repo-mirror.git
# git reflog expire --expire=now --all && git gc --prune=now --aggressive
# git push

DOC

echo
echo "Notes:"
echo " - These operations rewrite history. Coordinate with all collaborators."
echo " - Always backup (clone --mirror) before running."
echo " - Rotate any credentials that may have been exposed regardless of history rewrite."

echo "Prepared guidance printed above."
