#!/bin/bash
#
#
# Script installs a Centos Lab using virt-install
# First determine networking set up of host
# Second determine guests and functions
# Third run installs
# Fourth test networking

# Networking configuration. Written for Ubuntu. ToDo - expand to CentOS with uname -a check	#
# First determine networking set up								#
# Loop over nested case statement to test localhost first, then determine if user wants an	#
# ethernet bridge set up.									# 
# Problems --> not all ethernet iface will be eth0						#
# 	   --> must determine initial static ip or dhcp						#
# Written May 19, 2015										#

# Verify and Store Networking Configuration							#

echo "Determining host networking...."

for netw in $(ip addr show | grep ^[0-9] | cut -d' ' -f2)
do
case $netw in
	lo:)
		ping -c 1 127.0.0.1 > /dev/null
		[ $? -eq 0 ] && echo "localhost ok" || { echo "localhost not ok"; exit 1; } ;;
	eth[0-9]:)
		ipadrss=`ip addr show $netw | awk '/inet/{ print $2;exit; }' | cut -d"/" -f1` 
		ethdev=$netw
		ping -c 1 $ipadrss > /dev/null
		[ $? -eq 0 ] && echo "ethernet ok" || { echo "ethernet not ok"; exit 1; }
		echo "IP Address of host stored as $ipadrss";;
	br[0-100]:)
		echo "Bridged ethernet present"
		brdev=$netw
		bripadrss=`ip addr show $netw | awk '/inet/{ print $2;exit; }' | cut -d'/' -f1`
		ping -c 1 $bripadrss > /dev/null
		[ $? -eq 0 ] && echo "bridged ethernet ok" || { echo "bridged ethernet not ok"; exit 1; }
		echo "Ethernet Bridge IP address stored as $bripadrss";;
	virbr[0-100]:)
		echo "Virtual Bridge ethernet present"
		virdev=$netw
		vbripadrss=`ip addr show $netw | awk '/inet/{ print $2;exit; }' | cut -d'/' -f1`
		ping -c 1 $vbripadrss > /dev/null
		[ $? -eq 0 ] && echo "Virtual bridged ethernet ok" || { echo "Virtual bridged ethernet not ok"; exit 1; }
		echo "Virtual ethernet bridge IP address stored as $vbripadrss";;
	*)
		echo "Additional interface device $netw also detected. " 
		;;
esac
done

# Maybe use this later if we want to change networking 						#
#		read -p "Keep networking config Y[YES] or Configure bridge mode for external access B[BRIDGE]? " netchg
#		case $netchg in
#			Y)
#				echo "Networking configuration complete";;
#			B)
#				echo "Configuring bridge mode. Prepare for networking reset"
#				echo "Backing up current network configuration"
#				cp /etc/network/interfaces /etc/network/interfaces.bak
#				sudo apt-get install -y bridge-utils
#				echo "auto br100" >> /etc/network/Net="--network bridge=br0"interfaces
#				echo "iface br100 inet dhcp" >> /etc/network/interfaces
#				echo "	bridge_ports      eth0" >> /etc/network/interfaces
#				echo "  bridge_stp        off" >> /etc/network/interfaces
#				echo "  bridge_maxwait    0" >> /etc/network/interfaces
#				echo "  bridge_fd         0" >> /etc/network/interfaces
#				sudo systemctl restart networking
#				[ $? -eq 0 ] && echo "Bridge br100 configured from ethernet eth0" || { echo "Bridge set up failed. Exiting"; exit 1; }
#			#	;;
#			#*)
#				echo "Invalid Option. Press Y to keep NAT'd ethernet or B to configure bridge mode"	
#		esac
#		;;
#	br[0-100]:)
#		echo "Bridged ethernet present"
#		;;
#	*)Net="--network bridge=br0"
#		echo "Failed to determine interface type"
#		;;
#esac
#done
# End Network Config of Host
#
# Begin Determination of KVM guests to set up							#
#
# Create Menu to display for selecting type of VM to Set up. Loop menu display.			#

echo "We will now select virtual machines to create."

# function to display menus

show_menus() {
#	clear
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
	echo "~~~~~~~~ Virtual Machines Available ~~~~~~~~"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "1. Centos 7 Minimal Install with Networking~"
	echo "2. Centos 7 LDAP Server			 ~"
	echo "3. Centos 7 Basic Server with GUI		 ~"
	echo "4. Exit without installing VMs		 ~"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}
# read input from the keyboard and take a action
# Exit when user the user select 4 or 5 from the menu option.

read_options(){
	local choice
	read -p "Enter choice [ 1 - 4 ] " choice
	case $choice in
		1) echo "C7_min_install" ;;
		2) echo "C7_LDAP_Server" ;;
		3) echo "C7_Basic_wGUI" ;;
		4) echo "Exit No Changes" && exit 0  ;;
		*) echo -e "Error...Choose again" && sleep 2
	esac
}
 

install_server(){
	echo "Beginning configuration of host.."
	iso=CentOS-7-x86_64-NetInstall-1503.iso
#	for mirror in $(curl -s http://isoredirect.centos.org/centos/7/isos/x86_64/ | sed  "s/[<>']/\ /g" | awk '$1 ~ /^http/')
#	do
#		curl -Is $mirror$iso | grep OK > /dev/null
#		[ $? -eq 0 ] && Src="-l $mirror$iso"; break;
#	done
	read -p "Enter a Host Name --> " hostname
	diskname=$hostname'.qcow2'
	read -p "Enter amount of RAM to allocate in KB--> " ramalloc
	read -p "Enter number of CPUs to allocate --> " cpualloc
	Cpu="--vcpus=$cpualloc"
	OS="--os-variant=rhel7"
	Net="-w bridge$virdev"
	Disk="--disk path=/var/lib/libvirt/images/$diskname,size=8"
#	Remember to set source Src variable again	###
	virt-install -n $hostname -r $ramalloc $Cpu $OS $Net $Disk $Src --dry-run
	read -p "Install another [Y/N] ? "
	while true
	do
		case $cont in
			[yY]) echo "Returning to Main Menu";;
			[nN]) echo "Process complete";;
			*) echo "Valid Selections are [Y or N]" && sleep 3;;
		esac
	done
}

 
# -----------------------------------
# Step #4: Main logic - infinite loop
# ------------------------------------
while true
do
 
	show_menus
	read_options
	install_server
done


