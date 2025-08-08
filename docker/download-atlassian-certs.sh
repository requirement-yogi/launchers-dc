#!/bin/bash

set -u
set -e

mkdir upmconfig_truststore || true
cd upmconfig_truststore

FILE1="atlassian_mpac_root_ca_v1.crt"
FILE2="atlassian_mpac_intermediate_ca_v1.crt"
TRUSTSTORE_FILE="truststore.jks"
PASSWORD="atlassian"


if [[ -f "$FILE1" && -f "$FILE2" && -f "$TRUSTSTORE_FILE" ]] ; then
  echo "Trust store already exists."
  echo "Not downloading again, please delete ./upmconfig_truststore if you want to redownload the certs"
fi

# Download Atlassian's root certificates for app signing
wget https://confluence.atlassian.com/upm/files/1489470540/1489470539/1/1736436578282/atlassian_ca_bundle-v1.zip
unzip -o atlassian_ca_bundle-v1.zip

if [[ ! -f "$FILE1" ]] ; then echo "File not found: $FILE1" ; exit 1 ; fi
if [[ ! -f "$FILE2" ]] ; then echo "File not found: $FILE2" ; exit 2 ; fi

# Build a keystore
keytool -importcert -noprompt -alias atlz-root-cert -storepass "$PASSWORD" -keystore "$TRUSTSTORE_FILE" -file "$FILE1"
keytool -importcert -noprompt -alias atlz-intermediate-cert -storepass "$PASSWORD" -keystore "$TRUSTSTORE_FILE" -file "$FILE2"
keytool -list -noprompt -storepass "$PASSWORD" -keystore "$TRUSTSTORE_FILE"
