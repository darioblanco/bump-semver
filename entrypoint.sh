#!/bin/bash

# config
DEFAULT_BUMP=${INPUT_DEFAULT_BUMP:-patch}
WITH_V=${INPUT_WITH_V:-true}
PREFIX=${INPUT_PREFIX}

# fetch tags
git fetch --tags

# get latest tag
REFLIST=$(git rev-list --tags --max-count=1)
if [ -n "$PREFIX" ]
then
    TAG=$(git describe --tags --match "$PREFIX-*" "$REFLIST")
    # Remove prefix from semantic version field
    VERSION=${TAG//${PREFIX}-/}
else
    TAG=$(git describe --tags "$REFLIST")
    VERSION=TAG
fi
TAG_COMMIT=$(git rev-list -n 1 "$TAG")

# Remove `v` from semantic version field
if $WITH_V
then
    VERSION=${VERSION//v/}
fi

# get current commit hash for tag
COMMIT=$(git rev-parse HEAD)

if [ "$TAG_COMMIT" == "$COMMIT" ]; then
    echo "No new commits since previous tag. Skipping..."
    echo "::set-output name=tag::$TAG"
    exit 0
fi

# if there are none, start tags at 0.0.0
if [ -z "$TAG" ]
then
    LOG=$(git log --pretty=oneline)
    VERSION=0.0.0
else
    LOG=$(git log "$TAG..HEAD" --pretty=oneline)
fi

# get commit logs and determine home to bump the version
# supports #major, #minor, #patch (anything else will be 'minor')
case "$LOG" in
    *#major* ) VERSION=$(semver bump major $VERSION);;
    *#minor* ) VERSION=$(semver bump minor $VERSION);;
    *#patch* ) VERSION=$(semver bump patch $VERSION);;
    * ) VERSION=$(semver bump $DEFAULT_BUMP $VERSION);;
esac

NEW=$VERSION

# prefix with 'v'
if $WITH_V
then
    NEW="v$NEW"
fi

# prefix with custom string
if [ -n "$PREFIX" ]
then
    NEW="$PREFIX-$NEW"
fi

echo "$NEW"

# set outputs
echo "::set-output name=tag::$NEW"
echo "::set-output name=version::$VERSION"

# push new tag ref to github
DT=$(date '+%Y-%m-%dT%H:%M:%SZ')
FULL_NAME=$GITHUB_REPOSITORY
GIT_REFS_URL=$(jq .repository.git_refs_url "$GITHUB_EVENT_PATH" | tr -d '"' | sed 's/{\/sha}//g')

echo "$DT: **pushing tag $NEW to repo $FULL_NAME"

curl -s -X POST "$GIT_REFS_URL" \
-H "Authorization: token $INPUT_TOKEN" \
-d @- << EOF

{
  "ref": "refs/tags/$NEW",
  "sha": "$COMMIT"
}
EOF
