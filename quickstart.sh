#!/bin/bash

show_menu(){
 	clear
 	BAR="=========================================================="
 	echo "$BAR"
 	echo " 0] Generation: Keys, Host configuration by \".env\""
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

keygen_for_worker(){
 	set -e -u 
 	
 	# check if we should use the old PEM style for generating the keys
 	# --------
 	# check: https://www.openssh.com/txt/release-7.8
 	
 	PEM_OPTION=
 	
 	if [ "$#" -eq 1 ] && [ "$1" == '--use-pem' ]; then
 	    PEM_OPTION='-m PEM'
 	elif [ "$#" -eq 1 ]; then
 	    echo "Invalid argument '$1', did you mean '--use-pem'?"
 	    exit 1
 	fi
 	
 	# generate the keys
 	# --------
 	
 	mkdir -p keys/web keys/worker
 	
 	yes | ssh-keygen $PEM_OPTION -t rsa -f ./keys/web/tsa_host_key -N ''
 	yes | ssh-keygen $PEM_OPTION -t rsa -f ./keys/web/session_signing_key -N ''
 	
 	yes | ssh-keygen $PEM_OPTION -t rsa -f ./keys/worker/worker_key -N ''
 	
 	cp ./keys/worker/worker_key.pub ./keys/web/authorized_worker_keys
 	cp ./keys/web/tsa_host_key.pub ./keys/worker
}

conf_gen(){
Host_ip=$1
	## Create a new docker-compose.yml for the Stack install
	if [ ! -f .env ];then
		echo "HOST_IP=$Host_ip" > .env
		echo " docker-compose config file has been created as below!"
		cat .env
	fi
}


provisioning_docker(){
	## Create a new keys for worker & web communication
	if [ ! -f ./keys/web/tsa_host_key.pub ];then
		keygen_for_worker
	fi

	## Host IP address check for the external URL of the Service
	if [ ! -f /tmp/host_ip ];then
		Host_check=$(ip route | grep $(ip route | grep default | sed -e 's#[A-Za-z0-9].*dev ##g' | awk '{print $1}') | grep -v -e 'default' | sed -e 's#[0-9*.*].*src ##g' -e 's# ##g')
		echo "$BAR"
		# echo " Please insert an IP address of the Host:"
		echo " Default Host IP address is [$Host_check]. Do you need to use by Default? [y]" 
		echo "$BAR"
		read anw_check
			if [[ $anw_check =~ ^([yY][eE][sS]|[yY]) ]];then
				conf_gen $Host_check
			else
				echo " Please insert an IP address of the Host:"
				read Host_ipadd
					if [[ $Host_ipadd = "" ]];then
						echo "HOST IP address is empty!!. Please check again the IP address of the host."
						exit 1
					else
		 				conf_gen $Host_ipadd
						echo "$Host_ipadd" > /tmp/host_ip
					fi
			fi
	fi
}


checkout(){
	if [ ! -f docker-compose.yml ];then
		provisioning_docker
	fi
}

clear_setup(){
	rm -f /tmp/host_ip .env
	echo "Configuration set has been removed!!"

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
