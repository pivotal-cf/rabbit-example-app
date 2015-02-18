Installation
============

Inside the app repository, run the following commands:

```
  cf push test-app
  cf bind-service test-app my_rabbitmq_service
  cf restage test-app
```

Make sure that your vhost queues are in ha-mode. SSH onto one of the server nodes and run the following command:

```
PATH=$PATH:/var/vcap/packages/erlang/bin/:/var/vcap/packages/rabbitmq-server/bin
rabbitmqctl set_policy -p VHOST_NAME_HERE ha-all ".*" '{"ha-mode":"all", "ha-sync-mode":"automatic"}'
```

Usage
=====

To write messages to the queue: 

```
  http://your.app.url/write
```

To read messages from the queue: 

```
  http://your.app.url/read
```

