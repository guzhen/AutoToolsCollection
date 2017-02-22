#!/bin/bash

set -x

source cfg.sh

mkdir -pv $cfgroot/client-configs

cd $cfgroot/openvpn-ca
source vars
source $shroot/fix_var.sh
./build-key $1
mkdir -p $cfgroot/client-configs/files
chmod 700 $cfgroot/client-configs/files
cp -v $shroot/client.conf $cfgroot/client-configs/base.conf

cd $cfgroot/client-configs

KEY_DIR=$cfgroot/openvpn-ca/keys
OUTPUT_DIR=$cfgroot/client-configs/files
BASE_CONFIG=$cfgroot/client-configs/base.conf

cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>') \
    > ${OUTPUT_DIR}/${1}.ovpn
