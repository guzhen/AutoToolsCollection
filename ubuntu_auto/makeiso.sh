#!/bin/bash

set -x
source cfg.sh

mkdir -pv $iworkspace

target_preseed=$iworkspace/output.cfg

## make preseed file
cp -v preseed.base $target_preseed
sed -i "s/iusername/$iusername/g" $target_preseed
sed -i "s/ipassword/$ipassword/g" $target_preseed
sed -i "s/ihostname/$ihostname/g" $target_preseed
if [ -z $iscript_uri ]; then
  sed -i 's/d-i preseed\/late_command.*$//g' $target_preseed
else
  sed -i "s#iscript_uri#$iscript_uri#g" $target_preseed
fi

## make modified iso image
current_path="$(pwd)"
iso_exec="$(readlink -e iso.sh)"

cd $iworkspace
$iso_exec $iiso_file $target_preseed
