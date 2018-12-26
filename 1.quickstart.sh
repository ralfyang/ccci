#!/bin/bash

show_menu(){
 	clear
 	BAR="=========================================================="
 	echo "$BAR"
 	echo " 0] Generation: Keys, docker-compose-yml for host"
 	echo " 1] Up the Concourse stack"
 	echo " 2] Run the Concourse stack by Daemon"
 	echo " 3] Down the Concourse stack"
 	echo "RM] Clear the setup with docker-compose.yml"
 	echo "$BAR"
 	echo "What do you want ? [0 - 3 or RM]"
}

## Select Menu
show_menu
read Menu


conf_gen(){
Host_ip=$1
	## Create a new docker-compose.yml for the Stack install
	if [ -f docker-compose.yml.sample ];then
		cat docker-compose.yml.sample | sed -e "s/HOST_IP/$Host_ip/g" > ./docker-compose.yml
		echo " docker-compose.yml file has been created as below!"
		cat docker-compose.yml
	else
		echo " docker-compose.yml.sample is not existed here! Please check again."
		exit 1
	fi
}


provisioning_docker(){
	## Create a new keys for worker & web communication
	if [ ! -f ./keys/web/tsa_host_key.pub ];then
		./keygen_for_worker.sh
	fi

	## Host IP address check for the external URL of the Service
	if [ ! -f /tmp/host_ip ];then
		echo "$BAR"
		echo " Please insert an IP address of the Host:"
		echo "$BAR"
		read Host_ip
			if [[ $Host_ip = "" ]];then
				echo "HOST IP address is empty!!. Please check again the IP address of the host."
				exit 1
			else
				echo "$Host_ip" > /tmp/host_ip
				conf_gen $Host_ip
			fi
	else
		Host_ip=$(cat /tmp/host_ip)
			if [[ $Host_ip = "" ]];then
				echo "HOST IP address is empty!!. Please check again the IP address of the host."
				exit 1
			else
				conf_gen $Host_ip
			fi
	fi
}


checkout(){
	if [ ! -f docker-compose.yml ];then
		provisioning_docker
	fi
}

clear_setup(){
	rm -f /tmp/host_ip ./docker-compose.yml
}


	case $Menu in 
		0) provisioning_docker ;;
		1) checkout
		   docker-compose up ;;
		2) checkout
		   docker-compose up -d ;;
		3) docker-compose down ;;
		RM) clear_setup ;;
		*) show_menu ;;
	esac
