#!/usr/bin/bash

function help() {
cat <<HELP
Script for releasing new version of the gem to rubygems.

USAGE:
1) Tag a new version x.y.z:

     ./rel-eng/release.sh tag x.y.z

   This bumps the version in all places.
2) The changes can be reviewed now
3) Push the commits to remote git repo and rubygems:

     ./rel-eng/release.sh release
HELP
}


set -exo pipefail

function tag() {
    if ! git diff-index --quiet HEAD --; then
        echo 'This script requires clean working directory to proceed'
        exit 1
    fi

    # TODO: compute default if not specified
    NEW_VERSION=$1

    if ! echo $NEW_VERSION | grep '^[0-9]*\.[0-9]*\.[0-9]*$'; then
        echo "Version number '$NEW_VERSION' has to be in format x.y.z"
        exit 2
    fi

    # bump the version in gemspec
    sed -i "s|\(version = \)\"[0-9.]*\"$|\1\"$NEW_VERSION\"|" *.gemspec 

    git add *.gemspec

    cat <<MESSAGE
Successfully bumped the version to $NEW_VERSION.

When happy with the status, to release the new version to git and rubygems:

  ./rel-eng/release.sh release
MESSAGE
}

function release() {
    # Publish phase
    GEM_FILE=$(gem build *.gemspec | grep -io '[a-z0-9.-]*\.gem$')
    git push origin HEAD && git push origin --tags
    gem push $GEM_FILE
}

ACTION=$1
if [ "$ACTION" = "" ]; then
    ACTION=help
else
    shift
fi

$ACTION "$@"
