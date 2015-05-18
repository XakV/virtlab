#!/bin/bash
#
#
# Script installs a Centos Lab using virt-install
# First determine networking set up of host
# Second determine guests and functions
# Third run installs
# Fourth test networking

echo "Determining host networking...."
netw=`ip addr show | grep ^[0-9] | cut -d' ' -f2`

case $netw in
	':lo')
		ping -c 1 127.0.0.1 > /dev/null
		[ $? -eq 0 ] && echo "localhost ok" || { echo "localhost not ok"; exit 1; } ;;
	':eth[0-9]')
		ipadrss=`ip addr show | grep eth0$ | cut -d" " -f6 | cut -d'/' -f1`
		ping -c 1 $ipadrss > /dev/null
		[ $? -eq 0 ] && echo "ethernet ok" || { echo "ethernet not ok"; exit 1; }
		read -p "Keep ethernet config Y[YES] or Configure bridge mode for external access B[BRIDGE]? " netchg
		case $netchg in
			Y)
				echo "IP Address of host stored as $ipadrss";;
			B)
				echo "Configuring bridge mode. Prepare for networking reset"
				;;
			*)
				echo "Invalid Option. Press Y to keep NAT'd ethernet or B to configure bridge mode"	
				;;
		esac
	':br*')
		echo "Bridged ethernet present"
		;;
esac

# End Network Config of Host
	
