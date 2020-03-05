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

NGINX_VERSION=${NGINX_VERSION-1.14.0}

apt-get update && apt-get install -y sudo uuid-dev

bash <(curl -f -L -sS https://ngxpagespeed.com/install) \
     --assume-yes \
     --nginx-version ${NGINX_VERSION-latest} \
     --ngx-pagespeed-version latest-stable

cp /usr/local/nginx/sbin/nginx /app/bin/nginx-${STACK}