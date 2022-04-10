#!/bin/bash

dir=/local/repository

lower=$1
upper=$2
sudo pkill nr-ue
sudo bash $dir/scripts/connect-all-ues.sh $lower $upper