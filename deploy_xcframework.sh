#!/usr/bin/env bash
set -e
set -x

if [ "$#" -lt 4 ]; then
    echo "Illegal number of parameters"
    echo "usage: ./deploy_framework {XCFRAMEWORK_PATH} {RELEASE_VERSION} {FRAMEWORK_METADATA_FILES_PATH} {RELEASE_REPO_URL} {POD_REPO_URL}"
    echo "POD_REPO_URL is optional"
    exit 1
fi

# ARGS
# Inputs
XCFRAMEWORK_PATH=$1
RELEASE_VERSION=$2
FRAMEWORK_METADATA_FILES_PATH=$3

# Targets
RELEASE_REPO_URL=$4
POD_REPO_URL=$5


# Created Directories
BINARY_REPO_PATH=release-repo
POD_REPO_NAME=deployment_private_pod_repo

# Clone release repo
git clone $RELEASE_REPO_URL $BINARY_REPO_PATH

# Remove previous framework and metadata files
rm -rf $BINARY_REPO_PATH/*

# Copy framework and metadata files into release repo
cp -r $XCFRAMEWORK_PATH $BINARY_REPO_PATH/
cp $FRAMEWORK_METADATA_FILES_PATH/* $BINARY_REPO_PATH/

if [ $(ls ${BINARY_REPO_PATH} | wc -l) == 0 ]
then
  echo The binary repo is empty and there is nothing to push.
  exit 1
fi

cd $BINARY_REPO_PATH

# Verify version $RELEASE_VERSION does not already exist
if git show-ref --tags | egrep -q "refs/tags/$RELEASE_VERSION"
then
  echo ERROR: Version $RELEASE_VERSION exists.
  exit 1
fi

# Commit and push
git add *
git commit -m $RELEASE_VERSION
git push
git tag $RELEASE_VERSION
git push --tags

# Deploy PODSPEC if POD_REPO_URL is provided
if [ ! -z $POD_REPO_URL ]
then
  pod repo add $POD_REPO_NAME $POD_REPO_URL
  pod spec lint --allow-warnings --skip-import-validation --private
  pod repo push --allow-warnings --skip-import-validation $POD_REPO_NAME $(basename $COCOAPODS_SPEC_TEMPLATE)
fi

echo Success
