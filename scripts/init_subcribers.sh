#!/bin/bash

cd /root/open5gs/misc/db

# add default ue subscriber so user doesn't have to log into web ui
opc="E8ED289DEBA952E4283B54E88E6183CA"
i=0
while IFS= read -r newkey; do
  MSISDN=$( printf '%010d' "$i" )
  ./open5gs-dbctl add 90170$MSISDN $newkey $opc
  i=$((i+1))
done < /local/repository/scripts/keys.txt