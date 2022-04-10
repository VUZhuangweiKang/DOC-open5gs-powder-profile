#!/bin/bash

sudo pkill -9
sudo su && cd /root/UERANSIM
build/nr-gnb -c config/open5gs-gnb.yaml > logs/ran.log 2>&1 &
