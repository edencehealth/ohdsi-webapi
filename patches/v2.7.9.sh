#!/bin/sh
# CHANGES:
# --------
# nothing provided in this container
# 
# org.hibernate 5.4.2.Final -> 5.4.22.Final
# 
# fixing mssql broken migration
set -eux

sed -i.bak \
  -e 's#<scope>provided</scope>##g;' \
  -e 's#5.4.2.Final#5.4.22.Final#g;' \
  pom.xml

sed -i.bak \
  's#VARCHAR(MAX);#VARCHAR(1024);#g;' \
  ./src/main/resources/db/migration/sqlserver/V2.8.0.20200427161830__modify_user_login.sql
