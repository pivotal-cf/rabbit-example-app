Installation
============

Inside the app repository, run the following commands:

```bash
  cf push test-app
  cf bind-service test-app my_rabbitmq_service
  cf restage test-app
```

Usage
=====

To write messages to the queue:

```
  http://test-app.<YOUR_DOMAIN>/write
```

To read messages from the queue:

```
  http://test-app.<YOUR_DOMAIN>/read
```

License
=======

Released under the Apache 2.0 license

(c) 2015, Pivotal Software



