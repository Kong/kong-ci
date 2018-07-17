#!/usr/bin/env bash
set -e

### Setup basic environment
source ./setup_env.sh


### Download libgmp & libnettle

if [[ -n "$LIBGMP" ]]; then
  LIBGMP_DOWNLOAD=$DOWNLOAD_CACHE/libgmp-$LIBGMP
  mkdir -p $LIBGMP_DOWNLOAD
  if [[ ! -f "$LIBGMP" ]]; then
    pushd $DOWNLOAD_CACHE
      curl -s -S -L https://ftp.gnu.org/gnu/gmp/gmp-${LIBGMP}.tar.bz2 -O - | \
        tar xj
    popd
  fi
fi

if [[ -n "$LIBNETTLE" ]]; then
  LIBNETTLE_DOWNLOAD=$DOWNLOAD_CACHE/libnettle-$LIBNETTLE
  mkdir -p $LIBNETTLE_DOWNLOAD
  if [[ ! -f "$LIBNETTLE" ]]; then
    pushd $DOWNLOAD_CACHE
      curl -s -S -L https://ftp.gnu.org/gnu/nettle/nettle-${LIBNETTLE}.tar.gz -O - | \
        tar xz
    popd
  fi
fi


### Compile libgmp & libnettle

pushd $DOWNLOAD_CACHE/libgmp-${LIBGMP}
  ./configure \
    --build=x86_64-linux-gnu \
    --enable-static=no \
    --libdir=$INSTALL_CACHE/libs
  make
popd

pushd $DOWNLOAD_CACHE/libnettle-${LIBNETTLE}
  LDFLAGS="-Wl,-rpath,$INSTALL_CACHE/libs" \
  ./configure --disable-static \
  --libdir=$INSTALL_CACHE/libs \
  --with-include-path="$DOWNLOAD_CACHE/libgmp-${LIBGMP}/" \
  --with-lib-path="$DOWNLOAD_CACHE/libgmp-${LIBGMP}/.libs/"
  make
popd

### XXX libraries used in OIDC expect libgmp and libnettle to be in
### in a specific location - /usr/local/kong - defined in oidc's env.lua
### file. It'll need to be tweaked.
