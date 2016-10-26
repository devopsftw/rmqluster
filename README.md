RMQLUSTER
===========


```
docker run -it -e CONSUL_HOST=<whatever or default gateway> -e RABBITMQ_ERLANG_COOKIE=<supersecret> -e CLUSTER_WITH=<other rmqmachines, single entry, resolvable hostname ok> <image id>
```