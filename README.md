# Bump Semver

A Github Action to automatically bump and tag master with the latest
SemVer formatted version.

## Usage

```Dockerfile
name: Bump version
on:
  push:
    branches:
      - master
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Bump version and push tag
      uses: AlexisJasso/bump-semver@v1.0.3
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
        prefix: mygroup/
```

### Options

### Input Variables

* **token** ***(required)*** - Required for permission to tag the repo.
* **prefix** *(optional)* - Appends the given prefix to the tag
(e.g. PREFIX=myprefix-v would create a myprefix-v1.0.0 tag)
* **npm** *(optional)* - Update version in package.json file (default: `false`).
* **packageJsonPath** *(optional)* - Specify the path of the package.json file
(default: `package.json`).

### Outputs

* **tag** - The latest tag after running this action.
* **version** - The semantic version without any "v" or other prefixes.

> ***Note:*** This action creates a [lightweight tag](https://developer.github.com/v3/git/refs/#create-a-reference).

## Bumping

**Manual Bumping:** Any commit message that includes `#major`, `#minor`,
or `#patch` will trigger the respective version bump.
If two or more are present, the highest-ranking one will take precedence.

**Automatic Bumping:** If no `#major`, `#minor` or `#patch` tag is contained in
the commit messages, no tag will be created.

> ***Note:*** This action **will not** bump the tag if the `HEAD` commit has already been tagged.

## Workflow

* Add this action to your repo
* Commit some changes
* Either push to master or open a PR
* On push (or merge) to `master`, the action will:
  * Get latest tag
  * Bump tag with minor version unless any commit message contains `#major` or `#patch`
  * Pushes tag to github

## Credits

[minddocdev/mou-version-action](https://github.com/minddocdev/mou-version-action)

[fsaintjacques/semver-tool](https://github.com/fsaintjacques/semver-tool)

[anothrNick/github-tag-action](https://github.com/anothrNick/github-tag-action)

[darioblanco/bump-semver](https://github.com/darioblanco/bump-semver)
