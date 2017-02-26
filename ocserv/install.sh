#!/bin/bash

set -x
# input
tarball_url='https://github.com/openconnect/ocserv/archive/ocserv_0_11_7.tar.gz'
tarball_name='ocserv_0_11_7.tar.gz'
tarball_folder='ocserv-ocserv_0_11_7'
build_path=~/build-ocserv
# config
server_name=""
server_ip=192.168.1.100
dns_ip=192.168.1.1
use_port=6789
logfile=~/install.log
cert_folder=~/certifications
# cert conf (cert_cn_server should be correct ip or domain name)
cert_cn_ca="CA name"
cert_cn_server="Server name"
cert_org="organization name"

do_prerequisite()
{
    #sudo apt-get update
    sudo apt-get install -y build-essential
    # dependencies
    sudo apt-get install -y libgnutls28-dev libev-dev
    # optional
    sudo apt-get install -y libwrap0-dev libpam0g-dev liblz4-dev libseccomp-dev libreadline-dev libnl-route-3-dev libkrb5-dev liboath-dev libradcli-dev
    # development dependencies
    sudo apt-get install -y libprotobuf-c0-dev libtalloc-dev libhttp-parser-dev libpcl1-dev libopts25-dev autogen protobuf-c-compiler gperf liblockfile-bin nuttcp lcov libuid-wrapper libnss-wrapper libsocket-wrapper gss-ntlmssp libpam-oath 
    # not found: libpam-wrapper
    # other found dependencies
    sudo apt-get install -y autoconf libtool gnutls-bin
}

get_source()
{
    rm -rf $build_path
    mkdir -v $build_path
    cd $build_path
    curl -O $tarball_url
    tar xf $tarball_name
    cd $tarball_folder
}

build_source()
{
    chmod +x autogen.sh
    ./autogen.sh
    ./configure --sysconfdir=/etc/
    make
    make check
    sudo make install
    sudo mkdir -vp /usr/share/doc/ocserv
    sudo cp -rv $build_path/$tarball_folder/doc /usr/share/doc/ocserv/
    sudo mkdir /etc/ocserv
    sudo cp -v /usr/share/doc/ocserv/doc/sample.config /etc/ocserv/ocserv.conf
    rm -rf $build_path
}

make_cert()
{
    rm -rf $cert_folder
    mkdir -pv $cert_folder
    cd $cert_folder
    echo "cn = \"$cert_cn_ca\"
organization = \"$cert_org\"
serial = 1
expiration_days = 3650
ca
signing_key
cert_signing_key
crl_signing_key">ca.tmpl

    echo "cn = \"$cert_cn_server\"
organization = \"$cert_org\"
expiration_days = 3650
signing_key
encryption_key
tls_www_server">server.tmpl
    if [ ! -z $server_name ]; then echo "dns_name = \"$server_name\"">>server.tmpl;
    else echo "ip_address = \"$server_ip\"">>server.tmpl; fi

    # make cert
    certtool --generate-privkey --outfile ca-key.pem
    certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem
    certtool --generate-privkey --outfile server-key.pem
    certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem

    # copy cert
    sudo cp -v server-cert.pem server-key.pem ca-cert.pem /etc/ocserv/
}

modify_conf()
{
    cd /etc/ocserv
    local conf_file=ocserv.conf
    sudo sed -i 's/^auth = .\+$/auth = pam/' $conf_file
    sudo sed -i 's#^server-cert = .\+$#server-cert = /etc/ocserv/server-cert.pem#' $conf_file
    sudo sed -i 's#^server-key = .\+$#server-key = /etc/ocserv/server-key.pem#' $conf_file
    sudo sed -i 's#^ca-cert = .\+$#ca-cert = /etc/ocserv/ca-cert.pem#' $conf_file
    sudo sed -i 's/\(^route = .\+$\)/#\1/g' $conf_file
    sudo sed -i 's/\(^no-route = .\+$\)/#\1/g' $conf_file
    sudo sed -i 's/^try-mtu-discovery = false/try-mtu-discovery = true/' $conf_file
    sudo sed -i 's#^ipv4-network = .\+$#ipv4-network = '$server_ip'#' $conf_file
    sudo sed -i 's/^dns = .\+$/dns = '$dns_ip'/' $conf_file
    sudo sed -i 's/^tcp-port = .\+$/tcp-port = '$use_port'/' $conf_file
    sudo sed -i 's/^udp-port = .\+$/udp-port = '$use_port'/' $conf_file
    sudo sed -i 's/\(^default-domain = .\+$\)/#\1/' $conf_file
}

start_server()
{
    sudo cp -v /usr/share/doc/ocserv/doc/systemd/standalone/ocserv.service /lib/systemd/system/
    sudo sed -i 's#/usr/sbin/ocserv#/usr/local/sbin/ocserv#g' /lib/systemd/system/ocserv.service
    sudo systemctl enable ocserv.service  
    sudo systemctl start ocserv.service  
    systemctl status ocserv.service  
}

mainfunc()
{
    do_prerequisite
    get_source
    build_source
    make_cert
    modify_conf
    start_server
}

tmp_logfile=$(mktemp)
mainfunc 2>&1 | tee $tmp_logfile
mv -v $tmp_logfile $logfile
