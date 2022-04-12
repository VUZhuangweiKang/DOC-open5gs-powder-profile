#!/bin/bash

open5gs_node="pc821"
ran_node="pc494"
# ue_nodes=("pc488" "pc516" "pc500" "pc519")
ue_nodes=("pc516" "pc500" "pc519")

NUM_UE=$1
repo="/local/repository"

# step 1. start UEs on each node
num_ue_nodes=${#ue_nodes[@]}
step=`expr $NUM_UE / $num_ue_nodes`
lower=0
temp=()
for node in "${ue_nodes[@]}"; do
    upper=$((lower+step-1))
    ssh -p 22 VUZK@$node.emulab.net sudo pkill nr-ue
    ssh -p 22 VUZK@$node.emulab.net bash $repo/src/ue.sh $lower $upper
    lower=$((lower+step))
    UEs=$(ssh -p 22 VUZK@$node.emulab.net python3 $repo/src/getip.py)
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
for node in "${ue_nodes[@]}"
do
    ssh -p 22 VUZK@$node.emulab.net sudo pkill python3
done

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
    msg_size=64
    pro_time=10
    # echo "cd $repo/src/ && sh nr-binder $addr python3 UE.py --id $ueid --monitor_addr $monitor_addr -a $addr -p $port --peer_addr $peer_addr --peer_port $peer_port --msg_size $msg_size --pro_time $pro_time"
    ssh -p 22 VUZK@${ue_nodes[$((i%num_ue_nodes))]}.emulab.net "cd $repo/src/ && sh nr-binder $addr python3 UE.py --id $ueid --monitor_addr $monitor_addr -a $addr -p $port --peer_addr $peer_addr --peer_port $peer_port --msg_size $msg_size --pro_time $pro_time" > logs/ue$i.log 2>&1 &
    port=$peer_port
done

# step 4. start monitor
ssh -p 22 VUZK@$ran_node.emulab.net sudo pkill python3
ssh -p 22 VUZK@$ran_node.emulab.net sudo python3 $repo/src/monitor.py ${#UEIPs[@]}

# step 5. display experiment results
ssh -p 22 VUZK@$ran_node.emulab.net cat $repo/src/results.csv