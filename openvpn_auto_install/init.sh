#!/bin/bash

set -x

source cfg.sh

# install software
sudo apt update -qq
sudo apt install -y openvpn easy-rsa iptables-persistent

# config openvpn
mkdir -pv $cfgroot
make-cadir $cfgroot/openvpn-ca
cd $cfgroot/openvpn-ca
source vars
source $shroot/fix_var.sh
./clean-all
./build-ca
./build-key-server server
./build-dh
openvpn --genkey --secret keys/ta.key
cd $cfgroot/openvpn-ca/keys
sudo cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn
sudo cp $shroot/server.conf /etc/openvpn/server.conf
sudo sed -i "s/<dnsip>/$dnsip/g" /etc/openvpn/server.conf

# config network
sudo sed -i 's/#net.ipv4.ip_forward/net.ipv4.ip_forward/g' /etc/sysctl.conf
sudo sysctl -p
sudo iptables -A INPUT -i tun+ -j ACCEPT
sudo iptables -A FORWARD -i tun+ -j ACCEPT
sudo iptables -A FORWARD -i tun+ -o enp0s3 -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o tun+ -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 192.168.233.0/24 -o enp0s3 -j MASQUERADE
tempfile=(mktemp --tmpdir iptb.XXXXXXXX)
sudo iptables-save > $tempfile
sudo cp $tempfile /etc/iptables/rules.v4
sudo rm $tempfile

# make client
cd $shroot
./mkclient.sh 'client1'

# run server
sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server
sudo systemctl status openvpn@server
