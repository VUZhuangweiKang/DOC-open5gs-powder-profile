#!/bin/bash

# This script installs UERANSIM and its prerequisites on the ran node as root user then runs it. Configs still need to be adjusted.

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# load config values
source /local/repository/scripts/setup-config

# automate grub prompt during installation
echo "SET grub-pc/install_devices /dev/sda" | sudo debconf-communicate


echo "1. Install the UERANSIM dependencies."
cd ~
sudo apt -y --force-yes update 
DEBIAN_FRONTEND=noninteractive sudo apt -y --force-yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
sudo apt -y --force-yes install make g++ openjdk-11-jdk maven libsctp-dev lksctp-tools snapd
# getting cmake from apt installs an old version of cmake, so we have to get it from snap
sudo snap install cmake --classic
# maybe gets rid of grub popup manual enter req
# https://askubuntu.com/questions/146921/how-do-i-apt-get-y-dist-upgrade-without-a-grub-config-prompt

#echo "2. Set the JAVA_HOME environment variable."
#export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

echo "3. Clone UERANSIM."
cd ~
git clone --depth 1 --branch v3.2.0 https://github.com/aligungr/UERANSIM.git

echo "4. Change configs"
cp /local/repository/config/ueran-profile.yaml ~/UERANSIM/config/profile.yaml
cp /local/repository/config/ueran-gnb.yaml ~/UERANSIM/config/open5gs-gnb.yaml
mkdir ~/UERANSIM/config/open5gs-ue
cp /local/repository/config/ueran-ue.yaml ~/UERANSIM/config/open5gs-ue/ue-default.yaml

replace_in_file() {
    # $1 is string to find, $2 is string to replace, $3 is filename
    sed -i "s/$1/$2/g" $3
}

cd ~/UERANSIM/config/open5gs-ue
# autogenerate config files for each ue
upper=$(($NUM_UE_ - 1))

i=0
while IFS= read -r newkey; do
    file=ue"$i.yaml"
    defaultkey="465B5CE8B199B49FAA5F0A2EE238A6BC"
    cp ue-default.yaml $file
    replace_in_file $defaultkey $newkey $file
    defaultimsi="imsi-901700000000001"

    MSISDN=$( printf '%010d' "$i" )
    newimsi="imsi-90170$MSISDN"
    replace_in_file $defaultimsi $newimsi $file

    if [ "$i" -gt $upper ]; then
      break
    fi
    i=$((i+1))
done < /local/repository/scripts/keys.txt   


echo "4.Build UERANSIM"
cd ~/UERANSIM
make
