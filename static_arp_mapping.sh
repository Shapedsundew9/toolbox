#!/bin/bash

# If the TARGET_IP is not accessible create a static ARP mapping and try again.
# Can be run standalone but general usage assumes a higher layer retry if it exists with a none-zero exit code.
GATEWAY_IP="192.168.100.1"
TARGET_IP="192.168.100.107"
TARGET_HW_ADDR="60:57:18:28:48:8f"
SLEEP_SECONDS=5
ATTEMPTS=10


# Make sure the gateway is reachable.
echo "Waiting for gateway ${GATEWAY_IP} to come online."
if ! ping -c 1 -n -w 1 ${GATEWAY_IP} &> /dev/null
then
	echo "Gateway ${GATEWAY_IP} not online yet."
	sleep 1 # Throttling paranoia
	exit 1
fi

# Gateway is reachable - is the target?
echo "Testing if target ${TARGET_IP} is online."
if ping -c 1 ${TARGET_IP} &> /dev/null
then
	# If it is reachable then there is no need for a static ARP mapping. 
	echo "Target ${TARGET_IP} is online. Not statically defining ARP mapping."
else
	# Not reachable - try adding an ARP mapping.
	# The destination system needs an ARP mapping back so try several times before giving up.
	echo "Statically defining ARP mapping ${TARGET_IP} to ${TARGET_HW_ADDR}"	
	arp -s ${TARGET_IP} ${TARGET_HW_ADDR}
	echo "Waiting for target ${TARGET_IP} to be online."
	for i in {1..${ATTEMPTS}}; do
		if ping -c 1 ${TARGET_IP} &> /dev/null
		then
			# It worked!
			echo "Target ${TARGET_IP} is online."
			exit 0
		fi
		sleep ${SLEEP_SECONDS}
	done
	
	# Remove the entry. System may not be up yet so mop up the changes we made & await a higher layer retry (or not).
	echo "Target ${TARGET_IP} is still offline after ${ATTEMPTS} attempts at ${SLEEP_SECONDS}s intervals. Removing ARP cache entry."
	arp -d ${TARGET_IP}
	exit 1
fi
