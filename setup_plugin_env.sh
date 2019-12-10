#!/usr/bin/env bash

set -xe

function req_find {
  grep $2 $1 | head -n 1 | sed 's/.*=//'
}

export CI_TOOLS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# get Kong version and set up test environment
pushd $CI_TOOLS_DIR
  git clone https://github.com/Kong/$KONG_REPOSITORY.git
  pushd $KONG_REPOSITORY
    git checkout $KONG_TAG

    # Get requirements from .requirements file. Ignore whatever is in .travis
    # We cannot use `make setup-ci`, because we need to source it to have
    # the relevant environment variables set ($PATH, mainly)
    OPENRESTY=$(req_find .requirements RESTY_VERSION)
    LUAROCKS=$(req_find .requirements RESTY_LUAROCKS_VERSION)
    OPENSSL=$(req_find .requirements RESTY_OPENSSL_VERSION)
    OPENRESTY_PATCHES_BRANCH=$(req_find .requirements OPENRESTY_PATCHES_BRANCH)
    KONG_NGINX_MODULE_BRANCH=$(req_find .requirements KONG_NGINX_MODULE_BRANCH)
    BUILD_TOOLS=$(req_find .requirements BUILD_TOOLS)

    export OPENRESTY
    export LUAROCKS
    export OPENSSL
    export OPENRESTY_PATCHES_BRANCH
    export KONG_NGINX_MODULE_BRANCH
    export BUILD_TOOLS

    export PATH=$PATH:$PWD/bin

    source $CI_TOOLS_DIR/setup_env.sh

    make dev
  popd
popd

# set up Postgres database
createuser --createdb kong
createdb -U kong kong_tests

# Install the plugin
pushd $TRAVIS_BUILD_DIR
  luarocks make
  # build and export test commands
  export LUACHECK_CMD_="cd $TRAVIS_BUILD_DIR && luacheck ."
  export LUACHECK_CMD='echo EXECUTING: $LUACHECK_CMD_; '$LUACHECK_CMD_

  export BUSTED_CMD_="cd $CI_TOOLS_DIR/$KONG_REPOSITORY && bin/busted $BUSTED_ARGS $TEST_FILE_PATH"
  export BUSTED_CMD='echo EXECUTING: $BUSTED_CMD_; '$BUSTED_CMD_
popd

set +xe
