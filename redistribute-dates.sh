#!/usr/bin/env bash

set -euo pipefail

start_date="2024-04-05"
end_date=$(date +%Y-%m-%d)

# Check for GNU date
if ! date -d "$start_date" +%s >/dev/null 2>&1; then
    echo "❌ Error: GNU date required. On macOS, install with 'brew install coreutils' and use 'gdate'."
    exit 1
fi

# Check git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "❌ Error: Not in a git repository."
    exit 1
fi

start_ts=$(date -d "$start_date" +%s)
end_ts=$(date -d "$end_date" +%s)
range=$((end_ts - start_ts))

echo "🔍 Collecting commits from all branches (including merge commits)..."
IFS=$'\n' read -r -d '' -a commits < <(git rev-list --reverse --all --no-merges && printf '\0')
IFS=$'\n' read -r -d '' -a merge_commits < <(git rev-list --reverse --all --merges && printf '\0')
total=$((${#commits[@]} + ${#merge_commits[@]}))

if [[ $total -eq 0 ]]; then
    echo "❌ Error: No commits found."
    exit 1
fi

echo "📅 Total commits (regular: ${#commits[@]}, merge: ${#merge_commits[@]}): $total"
echo "📆 Redistributing dates from $start_date to $end_date..."

read -rp "⚠️ This will rewrite ALL BRANCHES' history. Backup done? (y/N): " confirm
if [[ "${confirm,,}" != "y" ]]; then
    echo "❌ Operation cancelled."
    exit 1
fi

# Create lookup file for commit => new date mapping
lookup_file=$(mktemp)
trap 'rm -f "$lookup_file"' EXIT

# Process regular commits
commit_count=${#commits[@]}
divisor=$(( commit_count > 1 ? commit_count - 1 : 1 ))

for i in "${!commits[@]}"; do
    commit="${commits[$i]}"
    offset=$((i * range / divisor))
    new_ts=$((start_ts + offset))
    new_date=$(date -d "@$new_ts" "+%Y-%m-%dT12:00:00")
    echo "$commit $new_date" >> "$lookup_file"
done

# Process merge commits: assign later of parents' dates + 1 min
for merge in "${merge_commits[@]}"; do
    parents=$(git log --pretty=%P -n 1 "$merge")
    latest_parent_date=""
    for parent in $parents; do
        parent_date=$(grep "^$parent " "$lookup_file" | awk '{print $2}')
        if [[ -z "$parent_date" ]]; then
            parent_date=$(git log -n 1 --pretty=%aI "$parent")
        fi
        if [[ -z "$latest_parent_date" || "$parent_date" > "$latest_parent_date" ]]; then
            latest_parent_date="$parent_date"
        fi
    done

    if [[ -n "$latest_parent_date" ]]; then
        merge_ts=$(date -d "$latest_parent_date" +%s)
        merge_ts=$((merge_ts + 60)) # +1 minute
        merge_date=$(date -d "@$merge_ts" "+%Y-%m-%dT12:00:00")
        echo "$merge $merge_date" >> "$lookup_file"
    fi
done

echo "⚡ Rewriting history for all branches and merge commits..."

FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f \
    --env-filter '
        new_date=$(grep "^$GIT_COMMIT " "'"$lookup_file"'" | awk "{print \$2}")
        if [ -n "$new_date" ]; then
            export GIT_AUTHOR_DATE="$new_date"
            export GIT_COMMITTER_DATE="$new_date"
        fi
    ' \
    --tag-name-filter cat \
    -- --all

echo "✅ Successfully redistributed commit dates across ALL branches and merge commits."
read -rp "⚠️ This will rewrite ALL BRANCHES' history. Backup done? (y/N): " confirm
if [[ "${confirm,,}" != "y" ]]; then
    echo "❌ Operation cancelled."
    exit 1
fi
echo "⚠️ You must now force-push to your remote to apply these rewritten dates:"
echo "   git push --force --all"
echo "   git push --force --tags"
