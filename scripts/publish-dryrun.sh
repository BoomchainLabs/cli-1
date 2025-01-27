 #!/usr/bin/env bash

set -eo pipefail

IS_LOCAL="false"
IS_CI="true"

if [ -z "$CI" ]; then
  echo "Running locally will overwrite your globally installed npm."
  GITHUB_SHA=$(git rev-parse HEAD)
  RUNNER_TEMP=$(mktemp -d)
  IS_LOCAL="true"
  IS_CI="false"
fi

if [ -z "$GITHUB_SHA" ]; then
  echo "Error: GITHUB_SHA is required"
  exit 1
fi

if [ -z "$RUNNER_TEMP" ]; then
  echo "Error: RUNNER_TEMP is required"
  exit 1
fi

ORIGINAL_GLOBAL_NPM_VERSION=$(npm --version)
if [ ${#ORIGINAL_GLOBAL_NPM_VERSION} -gt 40 ]; then
  echo "Error: Global npm version already contains a git SHA ${ORIGINAL_GLOBAL_NPM_VERSION}"
  exit 1
fi

ORIGINAL_LOCAL_NPM_VERSION=$(node . --version)
if [ ${#ORIGINAL_LOCAL_NPM_VERSION} -gt 40 ]; then
  echo "Error: Local npm version already contains a git SHA ${ORIGINAL_LOCAL_NPM_VERSION}"
  exit 1
fi
NPM_VERSION="$ORIGINAL_LOCAL_NPM_VERSION-$GITHUB_SHA.0"

# Only cleanup locally
if [ "$IS_LOCAL" == "true" ]; then
  function cleanup {
    npm pkg set version=$ORIGINAL_LOCAL_NPM_VERSION
    node scripts/resetdeps.js
    if [ "$(git rev-parse HEAD)" != "$GITHUB_SHA" ]; then
      echo "==================================="
      echo "==================================="
      echo "HEAD is on a different commit."
      echo "==================================="
      echo "==================================="
    fi
    if [ "$(npm --version)" == "$NPM_VERSION" ]; then
      echo "==================================="
      echo "==================================="
      echo "Global npm version has changed to $NPM_VERSION"
      echo "Run the following to change it back"
      echo "npm install npm@$ORIGINAL_GLOBAL_NPM_VERSION -g"
      echo "==================================="
      echo "==================================="
    fi
  }
  trap cleanup EXIT
fi

# this script leaves the repo dirty
node scripts/publish.js --pack-destination=$RUNNER_TEMP --smoke-publish=true
