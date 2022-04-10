#!/bin/bash
replace_in_file() {
    # $1 is string to find, $2 is string to replace, $3 is filename
    sed -i "s/$1/$2/g" $3
}

# load config values
source /local/repository/scripts/setup-config

cd ~/UERANSIM/config/open5gs-ue
# autogenerate config files for each ue
upper=$(($NUM_UE_ - 1))
i=0
while IFS= read -r newkey; do
    file=ue"$i.yaml"
    defaultkey="465B5CE8B199B49FAA5F0A2EE238A6BC"
    cp ue-default.yaml $file
    replace_in_file $defaultkey $newkey $file
    defaultimsi="imsi-901700000000001"

    MSISDN=$( printf '%010d' "$i" )
    newimsi="imsi-90170$MSISDN"
    replace_in_file $defaultimsi $newimsi $file

    if [ "$i" -gt $upper ]; then
      break
    fi
    i=$((i+1))
done < /local/repository/scripts/keys.txt