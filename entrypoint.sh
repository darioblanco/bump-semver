#!/bin/bash

# config
default_semvar_bump=${DEFAULT_BUMP:-patch}
with_v=${WITH_V:-false}
prefix=${PREFIX}

# fetch tags
git fetch --tags

# get latest tag
tag=$(git describe --tags `git rev-list --tags --max-count=1`)
tag_commit=$(git rev-list -n 1 $tag)

# get current commit hash for tag
commit=$(git rev-parse HEAD)

if [ "$tag_commit" == "$commit" ]; then
    echo "No new commits since previous tag. Skipping..."
    echo ::set-output name=tag::$tag
    exit 0
fi

# if there are none, start tags at 0.0.0
if [ -z "$tag" ]
then
    log=$(git log --pretty=oneline)
    tag=0.0.0
else
    log=$(git log $tag..HEAD --pretty=oneline)
fi

# get commit logs and determine home to bump the version
# supports #major, #minor, #patch (anything else will be 'minor')
case "$log" in
    *#major* ) new=$(semver bump major $tag);;
    *#minor* ) new=$(semver bump minor $tag);;
    *#patch* ) new=$(semver bump patch $tag);;
    * ) new=$(semver bump `echo $default_semvar_bump` $tag);;
esac

# prefix with 'v'
if $with_v
then
    new="v$new"
fi

if [ ! -z $prefix ]
then
    new="$prefix-$new"
fi

echo $new

# set outputs
echo ::set-output name=new_tag::$new
echo ::set-output name=tag::$new

# push new tag ref to github
dt=$(date '+%Y-%m-%dT%H:%M:%SZ')
full_name=$GITHUB_REPOSITORY
git_refs_url=$(jq .repository.git_refs_url $GITHUB_EVENT_PATH | tr -d '"' | sed 's/{\/sha}//g')

echo "$dt: **pushing tag $new to repo $full_name"

curl -s -X POST $git_refs_url \
-H "Authorization: token $GITHUB_TOKEN" \
-d @- << EOF

{
  "ref": "refs/tags/$new",
  "sha": "$commit"
}
EOF
