#!/usr/bin/env python

#
# Standard geni-lib/portal libraries
#
import geni.portal as portal
import geni.rspec.pg as rspec
import geni.rspec.emulab as elab
import geni.rspec.igext as IG

tourDescription = """
This profile creates a 5G core via [Open5GS](https://github.com/open5gs/open5gs) and connects it to a simulated gNB Base Station and specified number of User Equipment (UE) via [UERANSIM](https://github.com/aligungr/UERANSIM). Everything is set up automatically to be able to connect a single UE to the netwowrk with IMSI 901700000000001.

The profile is known to work with UERANSIM v3.1.8 and Open5GS v2.2.7 (as of 5/3/2021). However, the profile downloads and builds the latest versions by default, so breaking changes could occur.

"""

tourInstructions = """
To set up the default UE (or UEs, if you changed the parameter) and get internet access through it, do the following:

1. Wait until after the startup scripts have finished (in the POWDER experiment list view, the startup column for each node should say 'Finished'). This may take 30+ minutes.
2. Open up three terminals and ssh into the sim-ran box in all three, then run `sudo su && cd /root/UERANSIM` in each. Because UERANSIM creates tunnel network interfaces for UE PDU sessions, root access is required.
3. In the first window, run `build/nr-gnb -c config/open5gs-gnb.yaml` to start the gNB. It should log a successful connection to the 5G core.
4. In the second window, run `build/nr-ue -c config/open5gs-ue.yaml` to connect the simulated UE to the gNB. It should log a successful connection, successful registration with the 5G core, and a PDU session message indicating the device is ready to communicate in the user plane. 
4. The previous step also creates a new linux interface `uesimtun0`, which you can now use to access the internet through the 5G core. For example, you can run `ping -I uesimtun0 google.com` to see data being sent and received.

Refer to https://open5gs.org/open5gs/docs/guide/01-quickstart/ to learn how to modify the system, such as registering new UE subscribers in the core or modifying 5G network function configuration.

There is a script at `/local/repository/scripts/connect-all-ues.sh` that can be run on sim-ran node to start and create PDU sessions (and therefore interfaces) for all generated UEs at once, which also tests them for internet connectivity.                        

"""

#
# Globals
#
class GLOBALS(object):
    SITE_URN = "urn:publicid:IDN+emulab.net+authority+cm"
    # Use kernel version required by free5gc: Ubuntu 18, kernel 5.0.0-23-generic
    UBUNTU18_IMG = "urn:publicid:IDN+emulab.net+image+reu2020:ubuntu1864std50023generic"
    # default type
    HWTYPE = "d430"
    SCRIPT_DIR = "/local/repository/scripts/"
    SCRIPT_CONFIG = "setup-config"


def invoke_script_str(filename):
    # populate script config before running scripts (replace '?'s)
    populate_config = "sed -i 's/NUM_UE_=?/NUM_UE_=" + str(params.uenum) + "/' " + GLOBALS.SCRIPT_DIR+GLOBALS.SCRIPT_CONFIG
    populate_config2 = "sed -i 's/UERANSIM_BRANCHTAG_=?/UERANSIM_BRANCHTAG_=" + str(params.ueransim_branchtag) + "/' " + GLOBALS.SCRIPT_DIR+GLOBALS.SCRIPT_CONFIG
    # also redirect all output to /script_output
    run_script = "sudo bash " + GLOBALS.SCRIPT_DIR + filename + " &> ~/install_script_output"
    return populate_config + " && " + populate_config2 + " && " +  run_script

#
# This geni-lib script is designed to run in the PhantomNet Portal.
#
pc = portal.Context()

#
# Create our in-memory model of the RSpec -- the resources we're going
# to request in our experiment, and their configuration.
#
request = pc.makeRequestRSpec()

# Optional physical type for all nodes.
pc.defineParameter("phystype",  "Optional physical node type",
                   portal.ParameterType.STRING, "",
                   longDescription="Specify a physical node type (d430,d740,pc3000,d710,etc) " +
                   "instead of letting the resource mapper choose for you.")

pc.defineParameter("uenum","Number of simulated UEs to generate and register (0-10)",
                   portal.ParameterType.INTEGER, 1, min=0, max=10)

pc.defineParameter("ueransim_branchtag","Which tag/branch of UERANSIM to install",
                   portal.ParameterType.STRING, "v3.2.0")


# Retrieve the values the user specifies during instantiation.
params = pc.bindParameters()
pc.verifyParameters()



gNBCoreLink = request.Link("gNBCoreLink")

# Add node which will run gNodeB and UE components with a simulated RAN.
sim_ran = request.RawPC("sim-ran")
sim_ran.component_manager_id = GLOBALS.SITE_URN
sim_ran.disk_image = GLOBALS.UBUNTU18_IMG
#sim_ran.docker_extimage = "ubuntu:20.04"
sim_ran.hardware_type = params.phystype 
sim_ran.addService(rspec.Execute(shell="bash", command=invoke_script_str("ran.sh")))
gNBCoreLink.addNode(sim_ran)

# Add node that will host the 5G Core Virtual Network Functions (AMF, SMF, UPF, etc).
open5gs = request.RawPC("open5gs")
open5gs.component_manager_id = GLOBALS.SITE_URN
open5gs.disk_image = GLOBALS.UBUNTU18_IMG
#open5gs.docker_extimage = "ubuntu:20.04"
open5gs.hardware_type = GLOBALS.HWTYPE if params.phystype != "" else params.phystype
open5gs.addService(rspec.Execute(shell="bash", command=invoke_script_str("open5gs.sh")))
gNBCoreLink.addNode(open5gs)

tour = IG.Tour()
tour.Description(IG.Tour.MARKDOWN, tourDescription)
tour.Instructions(IG.Tour.MARKDOWN, tourInstructions)
request.addTour(tour)


pc.printRequestRSpec(request)
