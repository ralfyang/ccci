#!/bin/bash
## ccci is a tool for Concourse Centralized management Console Interface(via API)
## Made by Ralf Yang - https://github.com/goody80
## Version 0.4

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
Server_type=$1
 	set -e -u 
 	# generate the keys
 	# --------

 	## for total set
	case $Server_type in
		total)
		 	mkdir -p keys/web keys/worker
		 	ssh-keygen  -t rsa -f ./keys/web/tsa_host_key -N ''
		 	ssh-keygen  -t rsa -f ./keys/web/session_signing_key -N ''
 		 	ssh-keygen  -t rsa -f ./keys/worker/worker_key -N ''
 		 	cp ./keys/worker/worker_key.pub ./keys/web/authorized_worker_keys
		 	cp ./keys/web/tsa_host_key.pub ./keys/worker
			;;
		master)
		 	mkdir -p keys/web
		 	ssh-keygen  -t rsa -f ./keys/web/tsa_host_key -N ''
		 	ssh-keygen  -t rsa -f ./keys/web/session_signing_key -N ''
			## have to be send a Public key to consul for connection each other by command
			echo "$BAR"
			echo "You need to add a public-key(./keys/web/tsa_host_key.pub) to worker's key directory as below"
			echo "$BAR"
			cat ./keys/web/tsa_host_key.pub
			echo "$BAR"
			echo " to ./keys/worker/tsa_host_key.pub of worker's host. follow the command"
			echo " cat > ./keys/worker/tsa_host_key.pub"
			;;
		worker)
		 	mkdir -p keys/worker
 		 	ssh-keygen  -t rsa -f ./keys/worker/worker_key -N ''
			## have to be send a Public key to consul for connection each other by command
			echo "$BAR"
			echo "You need to add a public-key(./keys/worker/worker_key.pub) to master(web)'s authorized_worker_keys(./keys/web/authorized_worker_keys) as below"
			echo "$BAR"
			echo "echo \"$(cat ./keys/worker/worker_key.pub)\" >> ./keys/web/authorized_worker_keys"
			echo "$BAR"
			;;
	esac
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

select_server_type(){
	echo "$BAR"
	echo "1. Concourse web + worker + console"
	echo "2. Concourse web + console"
	echo "3. Concourse worker"
	echo "$BAR"
	echo "Please select server type as below: [1-3]"
	read S_type
		case $S_type in
			1) Server_type="total"
			   cp -f docker-compose-total.yml docker-compose.yml ;;
			2) Server_type="master"
			   cp -f docker-compose-server.yml docker-compose.yml ;;
			3) Server_type="worker"
			   cp -f docker-compose-worker.yml docker-compose.yml ;;
		esac
}

provisioning_docker(){
	## Create a new keys for worker & web communication
	if [ ! -d ./keys ];then
		select_server_type
		keygen_for_worker $Server_type
	fi

	## Host IP address check for the external URL of the Service
	if [ ! -f /tmp/host_ip ];then
		Host_check=$(ip route | grep $(ip route | grep default | sed -e 's#[A-Za-z0-9].*dev ##g' | awk '{print $1}') | grep -v -e 'default' | sed -e 's#[0-9*.*].*src ##g' -e 's# ##g')
		echo "$BAR"
		# echo " Please insert an IP address of the Host:"
		echo " Default Host IP address is [$Host_check]. Is that Concourse server IP address? [y]" 
		echo "$BAR"
		read anw_check
			if [[ $anw_check =~ ^([yY][eE][sS]|[yY]) ]];then
				conf_gen $Host_check
			else
				echo "$BAR"
				echo "Local IP list is like this below"
				ip addr |grep "inet " |fgrep -v "127.0.0.1" | awk '{print $2}' | sed -e 's#/[0-9].*##g'
				echo "$BAR"
				echo " Please type or copy & paste an IP address of the Host:"
				read Host_ipadd
					if [[ $Host_ipadd = "" ]];then
						echo "HOST IP address is empty!!. Please check again the IP address of the host."
						exit 1
					else
		 				conf_gen $Host_ipadd
					fi
				echo "$BAR"
				docker-compose config
			fi
	fi

}


checkout(){
	if [ ! -f docker-compose.yml ];then
		provisioning_docker
	fi
}

clear_setup(){
	rm -Rfv /tmp/host_ip .env docker-compose.yml ./keys
	echo "Configuration set has been removed!!"

}
	case $Menu in 
		0) provisioning_docker ;;
		1) checkout
		   docker-compose up ;;
		2) checkout
		   docker-compose up -d ;;
		3) docker-compose down ;;
		RM) docker-compose down && clear_setup ;;
		*) show_menu ;;
	esac
