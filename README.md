# open5gs-powder-profile

This is a [POWDER](https://powderwireless.net/) profile that automatically instantiates a full simulated 5g core network and UE RAN. It uses [Open5GS](https://github.com/open5gs/open5gs) for the 5c core, spread across 4 physical nodes, and uses [UERANSIM](https://github.com/aligungr/UERANSIM) v3.1.1 to simulate a gNB and UE devices on a fifth physical node.

This profile creates and registers a changeable number of UEs. There is a script at `/local/repository/scripts/connect-all-ues.sh` that can be run on sim-ran node to start and create PDU sessions (and therefore interfaces) for all 10 UEs at once, as well as test them all for internet connectivity.
