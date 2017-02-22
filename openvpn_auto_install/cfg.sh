#!/bin/bash

# path for running script
shroot="$(dirname "$(readlink -e $0)")"

# path for saving scipt
cfgroot=~/openvpn_cfg

# ip address for dns (router ip for normal case)
dnsip=192.168.1.1
