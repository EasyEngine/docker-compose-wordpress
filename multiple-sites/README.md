# Multiple Sites

### Usage

1. Start nginx-proxy once.
```
docker run --name nginx-proxy --restart always -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy
```

2. To create a new site, follow these steps.
```
project_name=site1.test
git clone https://github.com/EasyEngine/docker-compose-wordpress.git $project_name
cd $project_name/multiple-sites
sed -i "s/\(VIRTUAL_HOST: \)\(site1.test\)/\1$project_name/; s/\(VIRTUAL_HOST: \)\(mail.site1.test\)/\1mail.$project_name/; s/\(name: \)\(.*\)/\1$project_name/" docker-compose.yml
docker network create $project_name
docker network connect $project_name nginx-proxy
echo "127.0.0.1 $project_name" | sudo tee -a /etc/hosts

# Copy .env.example and edit the values.
mv .env.example .env
docker-compose up -d
```
Website will be available at [http://site1.test]()
Rinse and repeat for any number of sites.(provided you have resources on your system)

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
