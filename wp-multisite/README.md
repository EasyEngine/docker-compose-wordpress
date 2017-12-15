# WordPress Multisite

### Usage

1. Start nginx-proxy once.
```
docker run --name nginx-proxy -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy
```

2. To setup the multisite, follow these steps.
```
project_name=site1.test
git clone https://github.com/EasyEngine/docker-compose-wordpress.git $project_name
cd $project_name/wp-multisite
sed -i "s/\(VIRTUAL_HOST: \)\(.*\)/\1'$project_name,*.$project_name'/; s/\(name: \)\(.*\)/\1$project_name/" docker-compose.yml
docker network create $project_name
docker network connect $project_name nginx-proxy
echo "127.0.0.1 $project_name" | sudo tee -a /etc/hosts
docker-compose up -d
```

3. Configure multisite,
```
# SUBDIRECTORY
docker-compose exec --user=www-data php wp core multisite-install --title="WordPress Multisite Subdirectory" --admin_user="admin" --admin_password="password" --admin_email="user@example.com" --url=site1.test

# SUBDOMAIN
docker-compose exec --user=www-data php wp core multisite-install --title="WordPress Multisite Subdomains" --admin_user="admin" --admin_password="password" --admin_email="user@example.com" --url=site1.test --subdomains

# Add new site
docker-compose exec --user=www-data php wp site create --slug=example
echo "127.0.0.1 example.$project_name" | sudo tee -a /etc/hosts

# List all sites
docker-compose exec --user=www-data php wp site list --field=url
```

3. To stop a site, follow
```
project_name=site1.test
cd $project_name
docker-compose stop
```

4. To delete a site, follow
```
project_name=site1.test
cd $project_name
docker-compose down
cd ..
sudo rm -rf $project_name
docker network disconnect $project_name nginx-proxy
docker network rm $project_name
```

5. To check logs,
```
project_name=site1
cd $project_name
docker-compose logs -f
```
