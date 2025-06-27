#!/bin/sh

git filter-branch -f --env-filter '
NEW_NAME="Habtamu Alemayehu"
NEW_EMAIL="habtamualemayehu16@gmail.com"

if [ "$GIT_AUTHOR_EMAIL" = "dain@iq80.com" ] || \
   [ "$GIT_AUTHOR_EMAIL" = "martint@fb.com" ] || \
   [ "$GIT_AUTHOR_EMAIL" = "david@acz.org" ] || \
   [ "$GIT_AUTHOR_EMAIL" = "mtraverso@gmail.com" ] || \
   [ "$GIT_AUTHOR_EMAIL" = "49699333+dependabot[bot]@users.noreply.github.com" ]; then
    export GIT_AUTHOR_NAME="$NEW_NAME"
    export GIT_AUTHOR_EMAIL="$NEW_EMAIL"
fi

if [ "$GIT_COMMITTER_EMAIL" = "dain@iq80.com" ] || \
   [ "$GIT_COMMITTER_EMAIL" = "martint@fb.com" ] || \
   [ "$GIT_COMMITTER_EMAIL" = "david@acz.org" ] || \
   [ "$GIT_COMMITTER_EMAIL" = "mtraverso@gmail.com" ] || \
   [ "$GIT_COMMITTER_EMAIL" = "49699333+dependabot[bot]@users.noreply.github.com" ]; then
    export GIT_COMMITTER_NAME="$NEW_NAME"
    export GIT_COMMITTER_EMAIL="$NEW_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags
