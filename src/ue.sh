#!/bin/bash

lower=$1
upper=$2
repo="/local/repository"

[ ! -d "$repo" ] && git clone https://github.com/VUZhuangweiKang/DOC-open5gs-powder-profile.git $repo
sudo pkill nr-ue
sudo bash -c $repo/scripts/connect-all-ues.sh $lower $upper
