# Using
```
docker service create -eGIT_DEPLOY_KEY="-----BEGIN RSA PRIVATE KEY-----
dfdfewrwerwer
-----END RSA PRIVATE KEY-----
" -eGIT_REPO=ssh://git@github.com/root/repo.git -lcom.docker.stack.namespace=monitoring --container-label="com.docker.stack.namespace=monitoring" --name=php-worker --network=imig -p9000:9000 --replicas=2 --update-delay 30s logvik/php-worker-git-deploy:latest
```

# Result
You can set upstream for nginx config and make number of replicas as need just run
```
docker service update php-worker --replicas 5 --image logvik/php-worker-git-deploy:latest
```
If need just pull new code, then run 
```
docker service update php-worker --update-delay 31s --image logvik/php-worker-git-deploy:latest
```
in other time
```
docker service update php-worker --update-delay 30s --image logvik/php-worker-git-deploy:latest
```
Any service updates  will deploy new docker container and pull new code into container

# Use with Shadow demon server
Just uncomment in config/php/php.ini string
```
auto_prepend_file /usr/share/shadowd/Connector.php
```