#!/bin/bash
ue_nodes=("pc516" "pc500" "pc519")

for node in "${ue_nodes[@]}"; do
    ssh -p 22 VUZK@$node.emulab.net sudo pkill nr-ue
    ssh -p 22 VUZK@$node.emulab.net sudo pkill python3
done
