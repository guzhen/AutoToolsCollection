#!/bin/bash
set -x

if [ ! -e $STFILE ]; then
  echo 'status error'
  exit
fi

# read cfgs
source cfg.sh
echo $VNAME

# do disconnect
sudo poff $VNAME

# revert default route
sleep 2
source $STFILE
sudo ip route add $oldroute

# clean status
rm -f $STFILE
