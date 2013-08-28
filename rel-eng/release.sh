#!/usr/bin/bash

function help() {
cat <<HELP
Script for releasing new version of the gem both on rubygems and koji.

USAGE:
1) Tag a new version x.y.z:

     ./rel-eng/release.sh tag x.y.z

   This bumps the version on all places an tags the commit using tito tag
2) The changes can be reviewed now
3) Push the commtis to remote git repo, rubygems and koji:

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
    # bump the version in RPM spec
    sed -i "s|^\(Version: \)[0-9.]*$|\1$NEW_VERSION|" *.spec 
    # reset the release number; tito tag --keep-version doesn't do it for us
    sed -i "s|^\(Release: \)[0-9.]*|\11|" *.spec 

    git add *.gemspec *.spec

    # use the version we just specified in the RPM spec
    tito tag --keep-version
    # sanity check
    tito build --test --srpm
    cat <<MESSAGE
Successfully bumped the version to $NEW_VERSION.
You can review the changes or try to test build the rpm by runnig:

  tito build --test --rpm

To undo the action run:

  tito tag -u --offline

When happy with the status, to release the new version to git, rubygems and koji:

  ./rel-eng/release.sh release
MESSAGE
}

function release() {
    # Publish phase
    GEM_FILE=$(gem build *.gemspec | grep -io '[a-z0-9.-]*\.gem$')
    git push origin HEAD && git push origin --tags
    tito release koji
    gem push $GEM_FILE
}

ACTION=$1
if [ "$ACTION" = "" ]; then
    ACTION=help
else
    shift
fi

$ACTION "$@"
