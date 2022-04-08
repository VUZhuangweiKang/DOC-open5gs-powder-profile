#!/bin/bash

#n this script should be run as root
# print every command
set -x

# load configs 
source /local/repository/scripts/setup-config

### Enable IPv4/IPv6 Forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
sysctl -w net.ipv4.ip_nonlocal_bind=1
#echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
#sysctl -p /etc/sysctl.conf

# disable kernel sctp for now
modprobe -rf sctp

### Add NAT Rule
# Probably need to change these values?
sudo iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
sudo ip6tables -t nat -A POSTROUTING -s 2001:230:cafe::/48 ! -o ogstun -j MASQUERADE


# install open5gs
apt -y update
apt -y install software-properties-common
add-apt-repository ppa:open5gs/latest
apt -y update
apt -y install npm open5gs # might have to press enter here

echo Now install Open5GS Web UI

# install open5gs web UI
curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt -y install nodejs
curl -sL https://open5gs.org/open5gs/assets/webui/install | bash -
#curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
#curl -sL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -


echo "Setup 4G/ 5G NSA Core"

cp /local/repository/config/mme.yaml /etc/open5gs/mme.yaml
cp /local/repository/config/sgwu.yaml /etc/open5gs/sgwu.yaml

systemctl restart open5gs-mmed
systemctl restart open5gs-sgwud

echo "Setup 5G Core"

cp /local/repository/config/amf.yaml /etc/open5gs/amf.yaml
cp /local/repository/config/upf.yaml /etc/open5gs/upf.yaml

replace_in_file() {
    # $1 is string to find, $2 is string to replace, $3 is filename
    sed -i "s/$1/$2/g" $3
}

# amf.yaml is templated at one spot where the dev interface is, since this changes between
# POWDER builds. For now, do an easy variable injection with sed. If there grows to be
# lots of templating we may want a more concrete solution.
localiface=$(route | grep 10.10.1.0 | grep -o '[^ ]*$')
replace_in_file {{local-interface}} $localiface /etc/open5gs/amf.yaml

systemctl restart open5gs-amfd
systemctl restart open5gs-upfd

# clone open5gs for dbctl script
cd /root
git clone https://github.com/open5gs/open5gs
cd open5gs/misc/db

# add default ue subscriber so user doesn't have to log into web ui
opc="E8ED289DEBA952E4283B54E88E6183CA"
i=0
while IFS= read -r newkey; do
  MSISDN=$( printf '%010d' "$i" )
  ./open5gs-dbctl add 90170$MSISDN $newkey $opc
  i=$((i+1))
done < /local/repository/scripts/keys.txt                                    
