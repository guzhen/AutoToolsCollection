#!/bin/bash
set -x

# read cfgs
source cfg.sh
echo $VNAME

# do connect
oldif=$(ifconfig -a | sed 's/[ \t].*//;/^$/d')
sudo pptpsetup --delete $VNAME
sudo pptpsetup --create $VNAME --server $VSERVER --username $VUSER --password $VPASS --encrypt
sudo pon $VNAME

# get ppp name
sleep 1
newif=$(ifconfig -a | sed 's/[ \t].*//;/^$/d')
for i in $newif
do
  if [[ $oldif =~ $i ]];then
    continue
  else
    diffif=$i
    break
  fi
done

if [ -z $diffif ]; then
  echo 'fail'
  exit
else
  echo 'ok'
fi

# do route
oldroute=$(ip route|grep default|tr -d '\n')
sudo ip route del default
sleep 2
sudo ip route add default dev $diffif

# save data for disconnect
echo "oldroute=\"$oldroute\"">$STFILE
echo "diffif=$diffif">>$STFILE
