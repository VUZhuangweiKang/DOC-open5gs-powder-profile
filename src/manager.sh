#!/bin/bash

open5gs_node="pc821"
ran_node="pc494"
# ue_nodes=("pc488" "pc516" "pc500" "pc519")
ue_nodes=("pc516" "pc500")

NUM_UE=$1
repo="/local/repository"

# step 1. start UEs on each node
num_ue_nodes=${#ue_nodes[@]}
lower=0
UEIPs=()
for node in "${ue_nodes[@]}"; do
    step=`expr $NUM_UE / $num_ue_nodes`
    upper=$((lower+step-1))
    # echo $lower $upper
    ssh -p 22 VUZK@$node.emulab.net bash $repo/src/ue.sh $lower $upper
    lower=$((lower+step))
    UEs=$(ssh -p 22 VUZK@$node.emulab.net python3 $repo/src/main.py)
    for ue in $UEs; do
        UEIPs+=($ue)
    done
done


echo ${UEIPs[@]} 