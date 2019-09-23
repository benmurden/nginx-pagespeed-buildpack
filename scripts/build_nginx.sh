#!/bin/bash
# Build NGINX and modules on Heroku.
#
# This program is meant to run during the "compile" phase for buildpacks.
#
# The build-essentials package is not available in the "run" phase, so we
# have to build it during the "compile" phase.
#
# Uncomment the line that reads `sh scripts/build_nginx.sh $1` in bin/compile to run this script.
#
# Once this runs and compiles, the binary is available at ~/nginx/bin/nginx
# The compile phase ends with a new "slug", which will have the binary available.
# Run a Heroku console to get a shell to a slug, and then download or transfer
# the binary out. Next, copy this binary back into the repo, and uncomment
# the changes to bin/compile.
#
# Inputs: $1 should be the Heroku build directory.

NGINX_VERSION=${NGINX_VERSION-1.14.0}
NPS_VERSION=${NPS_VERSION-1.13.35.2}

NGINX_TARBALL_URL=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
NPS_URL=https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}-beta.tar.gz

DEST_DIR=$1
TMP_DIR=${DEST_DIR}/compile-nginx
mkdir $TMP_DIR

cd $TMP_DIR
echo "Temp dir: $TMP_DIR"

echo "Downloading $NGINX_TARBALL_URL"
curl -L $NGINX_TARBALL_URL | tar xz

echo "Downloading $NPS_URL"
(
  cd nginx-${NGINX_VERSION} && curl -L $NPS_URL | tar xz
  cd incubator-pagespeed-ngx-${NPS_VERSION}-beta/
  PSOL_URL=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}-x64.tar.gz
  [ -e scripts/format_binary_url.sh ] && PSOL_URL=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
  echo "Downloading $PSOL_URL"
  wget ${PSOL_URL}
  tar -xzf $(basename ${PSOL_URL})
)

echo "Compiling nginx"
(
  mkdir ${DEST_DIR}/nginx
  cd nginx-${NGINX_VERSION}
  ./configure \
    --prefix=${DEST_DIR}/nginx \
    --add-module=${TMP_DIR}/nginx-${NGINX_VERSION}/incubator-pagespeed-ngx-${NPS_VERSION}-beta \
    --with-http_gzip_static_module \
    --with-http_ssl_module \
    --with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
    --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed' 

  make install
  touch ${DEST_DIR}/compiled-nginx.txt
)
