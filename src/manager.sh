#!/bin/bash

open5gs_node="pc821"
ran_node="pc494"
# ue_nodes=("pc488" "pc516" "pc500" "pc519")
ue_nodes=("pc516" "pc500")

NUM_UE=$1
repo="/local/repository"

# step 1. start UEs on each node
num_ue_nodes=${#ue_nodes[@]}
step=`expr $NUM_UE / $num_ue_nodes`
lower=0
temp=()
for node in "${ue_nodes[@]}"; do
    upper=$((lower+step-1))
    # echo $lower $upper
    ssh -p 22 VUZK@$node.emulab.net bash $repo/src/ue.sh $lower $upper
    lower=$((lower+step))
    UEs=$(ssh -p 22 VUZK@$node.emulab.net python3 $repo/src/main.py)
    for ue in $UEs; do
        temp+=($ue)
    done
done

# step 2. shuffle UEs for cross-node communication
UEIPs=()
for i in $(seq 0 $(($step-1))); do
    for j in $(seq 0 $(($num_ue_nodes-1))); do
        k=$((j*step+i))
        UEIPs+=(${temp[k]})
    done
done

# step 3. start ZMQ applications
port=3333
start_port=$port
monitor_addr=$(ssh -p 22 VUZK@$ran_node.emulab.net hostname --all-ip-addresses | cut -d' ' -f1)
for i in $(seq 0 $((${#UEIPs[@]}-1)));
do
    ueid=$i
    addr=${UEIPs[$i]}
    if [[ $i == $((${#UEIPs[@]}-1)) ]]; then
        peer_addr=${UEIPs[0]}
        peer_port=$start_port
    else
        peer_addr=${UEIPs[$((i+1))]}
        peer_port=$((port+1))
    fi
    init_num=$i
    msg_size=64
    pro_time=5
    echo $ueid $addr $port $peer_addr $peer_port $monitor_addr $init_num $msg_size $pro_time
    # ssh -p 22 VUZK@${ue_nodes[$((i%num_ue_nodes))]}.emulab.net python3 $repo/src/UE.py $ueid $addr $port $peer_addr $peer_port $monitor_addr $init_num $msg_size $pro_time > ue$i.log 2>&1 &
    port=$peer_port
done