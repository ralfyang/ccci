#!/bin/bash
## ccci is a tool for Concourse Centralized management Console Interface(via API)
## Made by Ralf Yang - https://github.com/goody80
## Version 0.4
BAR="=========================================================="
BAR2="\033[31m==========================================================\033[0m"

Host_port=8080

# Consul check #
chk_consul_url(){
	clear
	if [ ! -f .consul_url ];then
		echo -e "$BAR2"
		echo -n -e " Are you using \"Consul\" (\033[1;32m"yes"\033[0m/\033[1;33m"no"\033[0m)? : "
		read consul_check
		consul_check=$(echo "$consul_check" |sed -e 's/\(.*\)/\L\1/')
		echo -e "$BAR2"
			if [[ $consul_check = "y" ]] || [[ $consul_check = "yes" ]]  ;then
				echo " ex: http(s)://consul.example.com "
				echo -n " Your \"Consul\" URL : "
				read consul_url
#	### http status code check
#				http_code=$(curl -o /dev/null --silent --head --write-out "%{http_code}" "$consul_url")
#				http_redirect=$(curl -o /dev/null --silent --head --write-out "%{redirect_url}" "$consul_url")
#				# SAMPLE #curl -o /dev/null --silent --head --write-out "$consul_url %{http_code} %{redirect_url}\n" "$consul_url"
#				echo "Your site : $consul_url, HTTP status : $http_code, Redirect URL : $http_redirect"

				if [[ $consul_url =~ ^(https?:\/\/)([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w_\.-]*)*\/?$ ]]; then
					echo " > URL ChEcK GoOd <" # >> ./log.log
					echo "$consul_url" > .consul_url
				else
					clear
					echo -e " Your \"Consul\" URL($consul_url) \033[31m"checking!"\033[0m "
				echo " ex: http(s)://consul.example.com "
				exit 1	
			fi
                else
			echo "Not used consul" # >> ./log.log
                fi
	fi
}

chk_consul_url

conf_gen(){
Host_ip=$1
	## Create a new docker-compose.yml for the Stack install
	if [ ! -f .env ];then
		echo "HOST_IP=$Host_ip" > .env
		echo " docker-compose config file has been created as below!"
		cat .env
	fi
}

chk_host_ip(){
	## Host IP address check for the external URL of the Service
	if [ ! -f .env ];then
		Host_check=$(ip route | grep $(ip route | grep default | sed -e 's#[A-Za-z0-9].*dev ##g' | awk '{print $1}') | grep -v -e 'default' | sed -e 's#[0-9*.*].*src ##g' -e 's# ##g')
		echo "$BAR"
		# echo " Please insert an IP address of the Host:"
		echo -e -n " Default Host IP address is \033[1;32m$Host_check\033[0m. Is that Concourse server IP address? [y] : " 
#		echo "$BAR"
		read anw_check
		echo "$BAR"
			if [[ $anw_check =~ ^([yY][eE][sS]|[yY]) ]];then
				conf_gen $Host_check
			else
				echo "Local IP list is like this below"
				ip addr |grep "inet " |fgrep -v "127.0.0.1" | awk '{print $2}' | sed -e 's#/[0-9].*##g'
				echo "$BAR"
				echo -n " Please type or copy & paste an IP address of the Host : "
				read Host_ipadd
					if [[ $Host_ipadd =~ ^((0|1[0-9]{0,2}|2[0-9]?|2[0-4][0-9]|25[0-5]|[3-9][0-9]?)\.){3}(0|1[0-9]{0,2}|2[0-9]?|2[0-4][0-9]|25[0-5]|[3-9][0-9]?)$ ]];then
		 				conf_gen $Host_ipadd
					else
						echo -e "\033[1;33m>> HOST IP address is empty or bad address!!. Please check again the IP address of the host.\033[0m"
						echo -e "\033[1;33m>> Your insert IP address : ${Host_ipadd}\033[0m "
						exit 1
					fi
				echo "$BAR"
#				docker-compose config
			fi
	fi
}
chk_host_ip

if [ -f .consul_url ];then
	consul_url=$(cat .consul_url)
fi
if [ -f .env ];then
	Host_ip_num=$(cat .env | awk -F"=" '{print $2}')
fi

##########################################################################################
show_menu(){
 #	clear
 	echo -e "$BAR2"
 	echo -e " 0] Generation: Keys, Host configuration by \"\033[1;31m".env"\033[0m\""
 	echo " 1] Up the Concourse stack"
 	echo " 2] Run the Concourse stack by Daemon"
 	echo " 3] Down the Concourse stack"
 	echo -e "RM] \033[41mClear the setup with docker-compose.yml\033[0m"
	if [[ "${consul_url}|${Host_ip_num}" != "" ]]; then
	echo "$BAR"
	fi
	if [ -f .consul_url ];then
		echo " >> Using Consul : $consul_url"
	fi
	if [ -f .env ];then
		echo " >> Setting Host IP : $Host_ip_num"
	fi
	echo -e "$BAR2"
 	echo -n "What do you want ? [0 - 3 or RM] : "
}

## Select Menu
show_menu
read Menu


#### peter MEMO# 
# $consul_url
# curl -sL -X PUT -d 'zzz' consul.mzdev.kr/v1/kv/kkkkkkkkkkkkkk 
# curl -sL -X PUT -d 'zzz' ${consul_url}/v1/kv/kkkkkkkkkkkkkk
# curl -sL -X DELETE ${consul_url}/v1/kv/kkkkkkkkkkkkkk
# echo true chk.
# curl consul.mzdev.kr/v1/kv/kkkkkkkkkkkkkk?raw
# curl -sL http://consul.mzdev.kr/v1/kv/concourse/hosts_pubkey/workers?keys | sed -e "s/,/\n/g" -e 's/\[//g' -e 's/\]//g' -e 's/"//g' | awk '{print "http://consul.mzdev.kr/v1/kv/"$0"?raw"}'


keygen_for_worker(){
Server_type=$1
consul_url=$consul_url
#Host_ip_num=$Host_ip_num
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
			if [[ $consul_url == "" ]]; then
				echo "You need to add a public-key(./keys/web/tsa_host_key.pub) to worker's key directory as below"
				echo "$BAR"
				cat ./keys/web/tsa_host_key.pub
				echo "$BAR"
				echo " to ./keys/worker/tsa_host_key.pub of worker's host. follow the command"
				echo " cat > ./keys/worker/tsa_host_key.pub"
			else
				pubkey_tsa=$(cat ./keys/web/tsa_host_key.pub)
				consul_puttsa=$(curl -sL -X PUT -d "$pubkey_tsa" ${consul_url}/v1/kv/concourse/hosts_pubkey/tsa)
				if [[ $consul_puttsa != "true" ]]; then
					echo -e " \033[31m"$consul_url RESTful HTTP API Fail"\033[0m"
					echo " to ./keys/worker/tsa_host_key.pub of worker's host. follow the command"
					echo " cat > ./keys/worker/tsa_host_key.pub"
					consul_puttsa_null=$(curl -sL -X DELETE ${consul_url}/v1/kv/concourse/hosts_pubkey/tsa)
				fi
				for i in $(curl -sL ${consul_url}/v1/kv/concourse/hosts_pubkey/workers?keys | sed -e "s/,/\n/g" -e 's/\[//g' -e 's/\]//g' -e 's/"//g' | awk -v zzz=$consul_url/v1/kv/ '{print zzz $0"?raw"}');do
					echo "$(curl -sL $i)" >> ./keys/web/authorized_worker_keys
				done
			fi
			;;
		worker)
			Master_checker=$(curl -si http://$Host_ip_num:$Host_port | head -1 | grep "OK")
			while true; do
				if [[ $Master_checker != ""  ]];then
					break
				fi
				sleep 5
				echo "- Checking for the concourse web(http://$Host_ip_num:$Host_port) server alives. Please wait..."
			done
		 	mkdir -p keys/worker
 		 	ssh-keygen  -t rsa -f ./keys/worker/worker_key -N ''
			## have to be send a Public key to consul for connection each other by command
			echo "$BAR"
			echo "You need to add a public-key(./keys/worker/worker_key.pub) to master(web)'s authorized_worker_keys(./keys/web/authorized_worker_keys) as below"
			echo -e "$BAR2"
			################## consul
			if [[ $consul_url == "" ]]; then
				echo "echo \"$(cat ./keys/worker/worker_key.pub)\" >> ./keys/web/authorized_worker_keys"
				echo -e "$BAR2"
			else
				pubkey_worker=$(cat ./keys/worker/worker_key.pub)
				consul_putwork=$(curl -sL -X PUT -d "$pubkey_worker" ${consul_url}/v1/kv/concourse/hosts_pubkey/workers/${Host_ip_num})
				if [[ $consul_putwork != "true" ]]; then
					echo -e " \033[31m"$consul_url RESTful HTTP API Fail"\033[0m"
					echo "echo \"$(cat ./keys/worker/worker_key.pub)\" >> ./keys/web/authorized_worker_keys"
					echo -e "$BAR2"
					consul_putwork_null=$(curl -sL -X DELETE ${consul_url}/v1/kv/concourse/hosts_pubkey/workers/${Host_ip_num})
				fi
				consul_getweb=$(curl -X GET http://consul.mzdev.kr/v1/kv/concourse/hosts_pubkey/tsa?raw)
				echo "$consul_getweb" > ./keys/worker/tsa_host_key.pub
					if [[ $consul_getweb != "true" ]]; then
						rm -rf ./keys/worker/tsa_host_key.pub
						echo "tsa key error" # >> log.log
					fi
			fi
			#######consul
			;;
	esac
}


select_server_type(){
	echo -e "$BAR2"
	echo "1. Concourse web + worker + console"
	echo "2. Concourse web + console"
	echo "3. Concourse worker"
	echo -e "$BAR2"
	echo -n "Please select server type as below: [1-3] "
	read -n 1 S_type
	echo
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
	else
		echo -e " \033[1;33m>> Existing configuration exists\033[0m "
		echo -e " \033[1;33m>> Please delete existing setting and execute.\033[0m "
	fi

}


checkout(){
	if [ ! -f docker-compose.yml ];then
		provisioning_docker
	fi
}

clear_setup(){
	rm -Rfv /tmp/host_ip .env docker-compose.yml ./keys .consul_url
	# curl key delete!!!! 
	echo "Configuration set has been removed!!"

}
	case $Menu in 
		0) provisioning_docker ;;
		1) checkout
		   docker-compose up ;;
		2) checkout
		   docker-compose up -d ;;
		3) docker-compose down ;;
		RM) docker-compose down
		    clear_setup ;;
		*) show_menu ;;
	esac
		
