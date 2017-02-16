#!/bin/bash
# Build NGINX and modules on Heroku.
# This program is designed to run in a web dyno provided by Heroku.
# We would like to build an NGINX binary for the builpack on the
# exact machine in which the binary will run.
# Our motivation for running in a web dyno is that we need a way to
# download the binary once it is built so we can vendor it in the buildpack.
#
# Once the dyno is 'up' you can open your browser and navigate
# this dyno's directory structure to download the nginx binary.

NGINX_VERSION=${NGINX_VERSION-1.11.10}
NPS_VERSION=${NPS_VERSION-1.12.34.2}

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
nps_url=https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VERSION}-beta.tar.gz

temp_dir=$(mktemp -d /tmp/nginx.XXXXXXXXXX)

echo "Serving files from /tmp on $PORT"
cd /tmp
python -m SimpleHTTPServer $PORT &

cd $temp_dir
echo "Temp dir: $temp_dir"

echo "Downloading $nginx_tarball_url"
curl -L $nginx_tarball_url | tar xz

echo "Downloading $nps_url"
( 
  cd nginx-${NGINX_VERSION} && curl -L $nps_url | tar xz
  cd ngx_pagespeed-${NPS_VERSION}-beta/
  psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
  [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
  echo "Downloading $psol_url"
  wget ${psol_url}
  tar -xzf $(basename ${psol_url})
)

(
  cd nginx-${NGINX_VERSION}
  ./configure \
    --add-module=${temp_dir}/nginx-${NGINX_VERSION}/ngx_pagespeed-${NPS_VERSION}-beta
    --prefix=/tmp/nginx \
    --with-http_gzip_static_module \
    --with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
    --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed' 

  make install
)

while true
do
  sleep 1
  echo "."
done