FROM alpine
LABEL "repository"="https://github.com/minddocdev/github-tag-action"
LABEL "homepage"="https://github.com/minddocdev/github-tag-action"
LABEL "maintainer"="MindDoc GmbH"

COPY ./contrib/semver ./contrib/semver
RUN install ./contrib/semver /usr/local/bin
COPY entrypoint.sh /entrypoint.sh

RUN apk update && apk add bash git curl jq

ENTRYPOINT ["/entrypoint.sh"]
