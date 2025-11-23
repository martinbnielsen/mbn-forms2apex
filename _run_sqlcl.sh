#!/bin/sh

# make sure script uses correct environment settings for sqlplus
source ~/.profile
export TNS_ADMIN=~/lib/instantclient_18_1/network/clientwallet

# run sqlplus, execute the script, then get the error list and exit
sqlplus $1 << EOF
ALTER SESSION SET PLSQL_WARNINGS = 'ENABLE:ALL';
$2
@_show_errors.sql
exit;
EOF