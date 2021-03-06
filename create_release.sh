#!/bin/sh -ex

./gradlew -q clean test distTar
./gradlew clean

git co master
git pull

VERSION="$1"
TAG_VERSION="${VERSION}.0"
BRANCH="release/$VERSION"

git co -b "$BRANCH"

git push origin "$BRANCH"

git tag "$TAG_VERSION"

git push origin "$TAG_VERSION"

RELEASE_BODY=$(cat <<EOF
{
  "tag_name": "${TAG_VERSION}",
  "target_commitish": "${BRANCH}",
  "name": "${TAG_VERSION}",
  "body": "Release ${TAG_VERSION}",
  "draft": false,
  "prerelease": false
}
EOF
)

RELEASE_ID=$(okurl -d "$RELEASE_BODY" https://api.github.com/repos/rsocket/rsocket-cli/releases | jq .id)

echo Created "https://api.github.com/repos/rsocket/rsocket-cli/releases/${RELEASE_ID}"

./gradlew -q clean distTar

oksocial -H "Content-Type: application/x-gzip" -d "@build/distributions/rsocket-cli-${TAG_VERSION}.tgz" "https://uploads.github.com/repos/rsocket/rsocket-cli/releases/${RELEASE_ID}/assets?name=rsocket-cli-${TAG_VERSION}.tgz" | jq ".browser_download_url"
