#!/bin/sh
# CHANGES:
# --------
# nothing provided in this container
#
# switch repo.ohdsi.org to TLS
# see https://maven.apache.org/docs/3.8.1/release-notes.html and
# https://github.com/OHDSI/WebAPI/issues/1825
set -eux

sed -i.bak \
  -e 's#<scope>provided</scope>##g;' \
  -e 's#http://repo.ohdsi.org:8085#https://repo.ohdsi.org#g;' \
  -e 's#54.209.111.128#127.0.0.1#g;' \
  pom.xml
