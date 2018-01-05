#!/usr/bin/env bash

DOCKER_COMPOSE_VERSION=1.18.0

###
#  Docker and Docker compose needs to be installed
###
if [ -x "$(command -v docker)" ]; then
	if [ -x "$(command -v docker-compose)" ]; then
		:
	else
		echo "Installing docker-compose, please wait..." && sleep 1
		sudo curl -L https://github.com/docker/compose/releases/download/"${DOCKER_COMPOSE_VERSION}"/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
		sudo chmod +x /usr/local/bin/docker-compose
	fi
else
	echo "Installing docker, please wait..." && sleep 1
	curl -fsSL get.docker.com | sh
fi

###
#  jwilder/nginx-proxy container needs to be running
###
docker inspect -f '{{.State.Running}}' nginx-proxy
nginx_proxy_status=$?
if [[ "$nginx_proxy_status" != 0 ]]; then
	echo "Starting jwilder/nginx-proxy container..." && sleep 1
	docker run --name nginx-proxy --restart always -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy
fi

###
#  Set project_name and deployment_method
###
if [[ "$#" -eq 0 ]]; then
	echo -n "Enter your project name(eg: example.com): "
	read project_name
	deployment_method=none
elif [[ "$#" -ge 1 ]]; then
	project_name=$1
fi

deployment_method=${2:-none}

echo "Project Name: $project_name"
echo "Deployment Method: $deployment_method"

###
#  Setup the project
###
mkdir -p /var/www
pushd /var/www > /dev/null 2>&1
	pwd
	echo "Configuring project..." && sleep 1
	tmpdir="$(mktemp -d)"
	git clone https://github.com/EasyEngine/docker-compose-wordpress.git "$tmpdir"
	mkdir "$project_name"
	rsync -a $tmpdir/multiple-sites/ $project_name
	rm -rf $tmpdir
	pushd $project_name > /dev/null 2>&1
		pwd
		ls -al
		sed -i "s/\(VIRTUAL_HOST=\)\(site1.test\)/\1$project_name/; s/\(VIRTUAL_HOST=\)\(mail.site1.test\)/\1mail.$project_name/;s/\(name: \)\(.*\)/\1$project_name/" docker-compose.yml
		if [[ "$deployment_method" == "deployer" ]]; then
			mv .env.deployer wordpress/.env
			sed -i 's#html#html/current#' config/nginx/default.conf
			sed -i '30a \    entrypoint: ["/bin/bash", "-c"]\n    command: ["php-fpm"]' docker-compose.yml
		fi

		###
		#  Setup networking
		###
		docker network create $project_name
		docker network connect $project_name nginx-proxy

		###
		#  Start the containers
		###
		mv .env.example .env
		echo "Starting containers..." && sleep 1
		docker-compose up -d
		chown -R www-data: wordpress
	popd > /dev/null 2>&1
popd > /dev/null 2>&1
