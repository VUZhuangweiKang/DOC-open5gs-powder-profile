#!/bin/bash

# load configs
source /local/repository/scripts/setup-config

# kill all existing nr-ue processes first
pkill -f nr-ue

# start each ue and output logs to a new log directory
cd /root/UERANSIM
logdir=uelog
mkdir -p $logdir
upper=$(($NUM_UE_ - 1))
for i in $(seq 0 $upper); do
    file=ue"$i.yaml"                             
    build/nr-ue -c config/open5gs-ue/ue$i.yaml > $logdir/ue$i.log 2>&1 &
    echo started ue$i
done 

sleep 1

# for each ue, check for connectivity
upper=$(($NUM_UE_ - 1))
for i in $(seq 0 $upper); do
    iface=$(grep 'Connection setup for PDU session' $logdir/ue$i.log | grep -Eo 'uesimtun[0-9]*')
    if [[ $iface == "" ]]; then
        echo "No PDU session interface found for ue$i"
        continue
    fi
    
    if [[ "$(ping -I $iface -c 1 8.8.8.8 | grep '100% packet loss' )" == "" ]]; then
        echo "Internet connectivity is UP for ue$i on interface $iface"
    else
        echo "Internet connectivity is DOWN for ue$i on interface $iface"
    fi
done
