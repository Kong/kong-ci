#!/usr/bin/env bash
set -xe

# --------
# Defaults
# --------
BUILD_TOOLS=${BUILD_TOOLS:-master}
OPENRESTY_PATCHES_BRANCH=${OPENRESTY_PATCHES_BRANCH:-master}
KONG_NGINX_MODULE_BRANCH=${KONG_NGINX_MODULE_BRANCH:-master}
JOBS=${JOBS:-$(nproc)}


if [[ -z "$LUAROCKS" ]] || [[ -z "$OPENRESTY" ]] || [[ -z "$OPENSSL" ]]; then
  echo "need \$LUAROCKS, \$OPENRESTY and \$OPENSSL to build dependencies"
  exit 1
fi

# Add here any env var that makes the build different
DEPENDENCIES=(
    "$LUAROCKS"
    "$OPENRESTY"
    "$OPENRESTY_PATCHES"
    "$OPENSSL"
    "$KONG_NGINX_MODULE"
)
DEPS_HASH=$(echo $(IFS=, ; echo "${DEPENDENCIES[*]}") | md5sum | awk '{ print $1 }')

#---------
# Download
#---------
BUILD_TOOLS_DOWNLOAD=${BUILD_TOOLS_DOWNLOAD:-$HOME/openresty-build-tools}
mkdir -p $BUILD_TOOLS_DOWNLOAD
curl -sSL https://github.com/kong/openresty-build-tools/archive/${BUILD_TOOLS}.tar.gz \
          | tar -C ${BUILD_TOOLS_DOWNLOAD} -xz --strip-components=1
export PATH=$BUILD_TOOLS_DOWNLOAD:$PATH

#--------
# Install
#--------
INSTALL_ROOT=$INSTALL_CACHE/$DEPS_HASH

mkdir -p $INSTALL_ROOT

kong-ngx-build \
    --work $DOWNLOAD_CACHE \
    --prefix $INSTALL_ROOT \
    --openresty $OPENRESTY \
    --openresty-patches $OPENRESTY_PATCHES \
    --kong-nginx-module $KONG_NGINX_MODULE \
    --luarocks $LUAROCKS \
    --openssl $OPENSSL \
    -j $JOBS &> build.log || (cat build.log && exit 1)



OPENSSL_INSTALL=$INSTALL_ROOT/openssl
OPENRESTY_INSTALL=$INSTALL_ROOT/openresty
LUAROCKS_INSTALL=$INSTALL_ROOT/luarocks

export OPENSSL_DIR=$OPENSSL_INSTALL # for LuaSec install

export PATH=$OPENSSL_INSTALL/bin:$OPENRESTY_INSTALL/nginx/sbin:$OPENRESTY_INSTALL/bin:$LUAROCKS_INSTALL/bin:$PATH
export LD_LIBRARY_PATH=$OPENSSL_INSTALL/lib:$LD_LIBRARY_PATH # for openssl's CLI invoked in the test suite

eval `luarocks path`

# -------------------------------------
# Setup Cassandra cluster
# -------------------------------------
if [ -n "$CASSANDRA" ]
then
  echo "Setting up Cassandra"
  docker run -d --name=cassandra --rm -p 7199:7199 -p 7000:7000 -p 9160:9160 -p 9042:9042 cassandra:$CASSANDRA
  grep -q 'Created default superuser role' <(docker logs -f cassandra)
else
  echo "CASSANDRA environment variable not set: skipping setting up Cassandra"
fi


docker run -d --name grpcbin -p 15002:9000 -p 15003:9001 moul/grpcbin

nginx -V
resty -V
luarocks --version
openssl version

set +xe
