#!/usr/bin/env bash

set -e

export CI_TOOLS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
pushd $CI_TOOLS_DIR
source ./setup_env.sh


# get Kong version and set up test environment
cd $CI_TOOLS_DIR
git clone https://github.com/Kong/$KONG_REPOSITORY.git
cd $KONG_REPOSITORY
git checkout $KONG_TAG
make dev


# set up Postgres database
createuser --createdb kong
createdb -U kong kong_tests


# Install the plugin
cd $TRAVIS_BUILD_DIR
luarocks make


# build and export test commands
export LUACHECK_CMD_="cd $TRAVIS_BUILD_DIR && luacheck ."
export LUACHECK_CMD='echo EXECUTING: $LUACHECK_CMD_; '$LUACHECK_CMD_

export BUSTED_CMD_="cd $CI_TOOLS_DIR/$KONG_REPOSITORY && bin/busted $BUSTED_ARGS $TEST_FILE_PATH"
export BUSTED_CMD='echo EXECUTING: $BUSTED_CMD_; '$BUSTED_CMD_

popd
set +e
