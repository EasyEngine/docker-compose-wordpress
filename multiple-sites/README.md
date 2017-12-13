# Multiple Sites

### Usage
1. Start nginx-proxy once.
```
docker network create nginx-proxy-network
docker run --name nginx-proxy -d -p 80:80 --network nginx-proxy-network -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy
```

2. To create a new site, follow these steps
```
project_name=site1
git clone https://github.com/EasyEngine/docker-compose-wordpress.git $project_name
cd $project_name
sed -i "s/\(VIRTUAL_HOST: \)\(.*\)/\1$project_name/; s/\(name: \)\(.*\)/\1$project_name/" docker-compose.yml
docker network create $project_name
docker network connect $project_name nginx-proxy
echo "127.0.0.1 $project_name" | sudo tee -a /etc/hosts
```
