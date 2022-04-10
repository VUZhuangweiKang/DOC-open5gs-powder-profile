#!/bin/bash

simu_nodes=("pc488" "pc516" "pc500" "pc519")

# create UE interfaces
for node in "${simu_nodes[@]}"; do
    echo $node
    ssh -p 22 VUZK@$node.emulab.net ls /local/repository/scripts
done