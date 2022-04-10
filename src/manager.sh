#!/bin/bash

open5gs_node="pc821"
ran_node="pc494"
# ue_nodes=("pc488" "pc516" "pc500" "pc519")
ue_nodes=("pc488")

NUM_UE=$1
repo="~/repository"

# step 1. start UEs on each node
num_ue_nodes=${#ue_nodes[@]}
lower=0
for node in "${ue_nodes[@]}"; do
    step=`expr $NUM_UE / $num_ue_nodes`
    upper=$[$lower+$step]
    upper=$((lower+$step))
    echo $lower $upper
    ssh -p 22 VUZK@$node.emulab.net bash -c $repo/src/ue.sh $lower $upper
    lower=$((lower+step))
done