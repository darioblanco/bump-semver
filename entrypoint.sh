#!/bin/bash

# config
PREFIX=${INPUT_PREFIX}
NPM=${INPUT_NPM}
PACKAGE_JSON_PATH=${INPUT_PACKAGE_JSON_PATH}

git config --global --add safe.directory $PWD

# fetch tags
git fetch --tags

# get latest tag
REFLIST=$(git rev-list --tags --max-count=1)
if [ -n "$PREFIX" ]
then
    TAG=$(git describe --tags --match "$PREFIX*" "$REFLIST")
    # Remove prefix from semantic version field
    VERSION=${TAG//${PREFIX}/}
else
    TAG=$(git describe --tags "$REFLIST")
    VERSION=TAG
fi
TAG_COMMIT=$(git rev-list -n 1 "$TAG")

# get current commit hash for tag
COMMIT=$(git rev-parse HEAD)

if [ "$TAG_COMMIT" == "$COMMIT" ]; then
    echo "No new commits since previous tag. Skipping..."
    echo "tag=$TAG" >> $GITHUB_OUTPUT
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
    *#${PREFIX}major* ) VERSION=$(semver bump major "$VERSION");;
    *#${PREFIX}minor* ) VERSION=$(semver bump minor "$VERSION");;
    *#${PREFIX}patch* ) VERSION=$(semver bump patch "$VERSION");;
    * ) exit 0 ;;
esac

NEW=$VERSION

# prefix with custom string
if [ -n "$PREFIX" ]
then
    NEW="$PREFIX$NEW"
fi

echo "$NEW"

# set outputs
echo "tag=$NEW" >> $GITHUB_OUTPUT
echo "version=$VERSION" >> $GITHUB_OUTPUT

if [[ "$NPM" = true  && -f "$PACKAGE_JSON_PATH" ]]; then
    # update package.json
    jq ".version = \"$VERSION\"" "$PACKAGE_JSON_PATH" > "tmp" && mv "tmp" "$PACKAGE_JSON_PATH"
fi

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
