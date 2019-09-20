#!/usr/bin/env bash

set -e

function req_find {
  grep $2 $1 | head -n 1 | sed 's/.*=//'
}

export CI_TOOLS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# get Kong version and set up test environment
pushd $CI_TOOLS_DIR
  git clone https://github.com/Kong/$KONG_REPOSITORY.git
  pushd $KONG_REPOSITORY
    git checkout $KONG_TAG

    # Set sane defaults
    BUILD_TOOLS=${BUILD_TOOLS:-master}
    OPENRESTY_PATCHES=${OPENRESTY_PATCHES:-master}
    KONG_NGINX_MODULE=${KONG_NGINX_MODULE:-master}
    JOBS=${JOBS:-$(nproc)}

    # Get requirements from .requirements file. Ignore whatever is in .travis
    # We cannot use `make setup-ci`, because we need to source it to have
    # the relevant environment variables set ($PATH, mainly)
    OPENRESTY=$(req_find .requirements RESTY_VERSION)
    LUAROCKS=$(req_find .requirements RESTY_LUAROCKS_VERSION)
    OPENSSL=$(req_find .requirements RESTY_OPENSSL_VERSION)

    # Lol.. make sure that openresty-build-tools is not on our download
    # cache folder for their git clone command to not fail...
    rm -rf ${DOWNLOAD_CACHE}/openresty-build-tools
    # Alternatively, set it to something that travis is not caching...
    # But then openresty-build-tools will not use its cache...
    # DOWNLOAD_CACHE=$HOME/download-root

    # This tries to translate env vars from different repos into what kong
    # setup_env file wants
    export OPENRESTY_PATCHES_BRANCH=${OPENRESTY_PATCHES}
    export KONG_NGINX_MODULE_BRANCH=${KONG_NGINX_MODULE}
    export DOWNLOAD_ROOT=${DOWNLOAD_CACHE}
    export INSTALL_CACHE=${INSTALL_CACHE}
    export JOBS
    export OPENRESTY
    export LUAROCKS
    export OPENSSL

    # We need to explicitly source it to get the new PATH envs
    # so we cannot do "make setup-ci" without having to rework our paths
    source .ci/setup_env.sh
    make dev
  popd
popd

# set up Postgres database
createuser --createdb kong
createdb -U kong kong_tests

# .ci/setup_env will still not up cassandra as usual
# Only up if there's no a cassandra running
if [[ -n "$CASSANDRA" ]] && ! docker inspect cassandra; then
  echo "Setting up Cassandra"
  docker run -d --name=cassandra --rm -p 7199:7199 -p 7000:7000 -p 9160:9160 -p 9042:9042 cassandra:$CASSANDRA
  grep -q 'Created default superuser role' <(docker logs -f cassandra)
else
  echo "CASSANDRA environment variable not set: skipping setting up Cassandra"
fi


# Install the plugin
pushd $TRAVIS_BUILD_DIR
  luarocks make
  # build and export test commands
  export LUACHECK_CMD_="cd $TRAVIS_BUILD_DIR && luacheck ."
  export LUACHECK_CMD='echo EXECUTING: $LUACHECK_CMD_; '$LUACHECK_CMD_

  export BUSTED_CMD_="cd $CI_TOOLS_DIR/$KONG_REPOSITORY && bin/busted $BUSTED_ARGS $TEST_FILE_PATH"
  export BUSTED_CMD='echo EXECUTING: $BUSTED_CMD_; '$BUSTED_CMD_
popd
set +e
