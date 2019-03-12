#!/bin/bash
##
## Server Installer Script
## by M4rshall
##
## Copyright (c) FastPrivateNet 2018. All Rights Reserved
##

vpn_name=$1
vpn_password=$2

## Updating System and Installing OpenVPN and other Application
apt-get update
apt-get install openvpn squid ufw mysql-client unzip dos2unix -y

## Packet Forwarding
NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i '/net.ipv4.ip_forward=1/s/^#//g' /etc/sysctl.conf
ufw allow ssh
ufw allow 443/tcp
ufw allow 8000/tcp
sed -i 's/\(DEFAULT_FORWARD_POLICY=\).*/\1"ACCEPT"/' /etc/default/ufw
sed -i "11i# START OPENVPN RULES\n# NAT table rules\n*nat\n:POSTROUTING ACCEPT [0:0]\n# Allow traffic from OpenVPN client to $NIC\n-A POSTROUTING -s 10.8.0.0/8 -o $NIC -j MASQUERADE\nCOMMIT\n# END OPENVPN RULES\n" /etc/ufw/before.rules
echo y | ufw enable

## Download OpenVPN Files
cd /etc/openvpn/
rm *
wget https://raw.githubusercontent.com/fastprivatenet/serverfiles/master/$vpn_name.zip
unzip $vpn_name.zip

## Configure Squid Proxy
rm /etc/squid3/squid.conf
mv squid.con /etc/squid3/
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
sed -i "s/ipmokasito/$IP/g" /etc/squid3/squid.conf

clear
echo "Please type the Database IP"
read -p "IP: " -e -i 127.0.0.1 DBhost
echo ""
echo "Please type the Database Username"
read -p "DB Username: " -e -i FastPrivateNet DBuser
echo ""
echo "Please type the Database Password"
read -p "DB Password: " -e -i FastPrivateNet DBpass
echo ""
echo "Please type the Database Name"
read -p "DB Name: " -e -i FastPrivateNet DBname

## Configure Server
sed -i "s/DBhost/$DBhost/g" /etc/openvpn/script/login.sh
sed -i "s/DBuser/$DBuser/g" /etc/openvpn/script/login.sh
sed -i "s/DBpass/$DBpass/g" /etc/openvpn/script/login.sh
sed -i "s/DBname/$DBname/g" /etc/openvpn/script/login.sh
sed -i "s/ServerPrefix/$ServerPrefix/g" /etc/openvpn/script/login.sh

## Setting Permission
chmod 755 /etc/openvpn/*
dos2unix /etc/openvpn/script/login.sh

## Start OpenVPN and Squid Proxy
service openvpn restart
service squid3 restart
