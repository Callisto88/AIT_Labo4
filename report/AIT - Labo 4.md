# AIT - Labo 4

[TOC]

## Introduction

An introduction describing briefly the lab



## Task 0

### Questions

*1. Do you think we can use the current solution for a production environment? What are the main problems when deploying it in a production environment?*

La structure du labo précédent ne convient pas à une utilisation en production. En effet, la solution mise en place au labo 3 est beaucoup trop statique et implique trop de downtime pour être utilisé en production.

*2. Describe what you need to do to add new`webapp` container to the infrastructure. Give the exact steps of what you have to do without modifiying the way the things are done. Hint: You probably have to modify some configuration and script files in a Docker image.*

Il faut modifier le script de provisioning ([re]provision.sh) pour y ajouter des containers webapp supplémentaires. Aussi, il faut adapter la configuration d'HAProxy pour rajouter les noeuds correspondants.

*3. Based on your previous answers, you have detected some issues in the current solution. Now propose a better approach at a high level.*

Je propose d'utiliser Docker Swarm. Conformément à la documentation cette solution semble toute désignée pour addresser les problèmes évoqués dans les questions 1 et 2. 

https://docs.docker.com/engine/swarm/

*4. You probably noticed that the list of web application nodes is hardcoded in the load balancer configuration. How can we manage the web app nodes in a more dynamic fashion?*

On pourrait utiliser un template.

*5. Do you think our current solution is able to run additional management processes beside the main web server / load balancer process in a container? If no, what is missing / required to reach the goal? If yes, how to proceed to run for example a log forwarding process?*

Les containers tels que définis actuellement ne sont pas designés pour exécuter d'autres processus en parallèle.

*6. What happens if we add more web server nodes? Do you think it is really dynamic? It's far away from being a dynamic configuration. Can you propose a solution to solve this?*

### Tool installation

Comme mentionné dans mon rapport du précédent labo, j'ai rencontré des problèmes avec Vagrant qui m'ont empêché de mettre en place le setup tel que demandé. Malheureusement le problème n'étant toujours pas résolu à ce jour je ferai à nouveau abstraction de Vagrant dans ce laboratoire et utiliserai Docker-machine directement sur ma machine hôte.

### Setup de l'environnement

**docker-compose.yml**

```yaml
version: '3.3'
networks:
  app_net:
    driver: bridge
    ipam:
      driver: default
      config:
      - subnet: 172.16.238.0/24
services:
  haproxy:
    build:
      context: ./ha
      dockerfile: Dockerfile
    container_name: ha
    restart: always
    ports:
      - "80:80"
      - "1936:1936"
      - "9999:9999"
    links:
      - webapp1
      - webapp2
    environment:
      - S1_PORT_3000_TCP_ADDR=172.16.238.11
      - S2_PORT_3000_TCP_ADDR=172.16.238.12
    networks:
      app_net:
        ipv4_address: 172.16.238.10
  webapp1:
    image: softengheigvd/webapp:s1
    build:
      context: ./webapp
      dockerfile: Dockerfile
    container_name: s1
    restart: always
    expose:
      - "3000"
    environment:
      - SERVER_TAG=s1
      - SERVER_NAME=s1
      - SERVER_IP=172.16.238.11
    networks:
      app_net:
        ipv4_address: 172.16.238.11
  webapp2:
    image: softengheigvd/webapp:s2
    build:
      context: ./webapp
      dockerfile: Dockerfile
    container_name: s2
    restart: always
    expose:
      - "3000"
    environment:
      - SERVER_TAG=s2
      - SERVER_NAME=s2
      - SERVER_IP=172.16.238.12
    networks:
      app_net:
        ipv4_address: 172.16.238.12
```



```bash
$ docker ps

CONTAINER ID        IMAGE                     COMMAND                  CREATED             STATUS              PORTS                                                                NAMES
401696465b86        novagrant_haproxy         "/docker-entrypoint.…"   About an hour ago   Up About an hour    0.0.0.0:80->80/tcp, 0.0.0.0:1936->1936/tcp, 0.0.0.0:9999->9999/tcp   ha
39585f04808b        softengheigvd/webapp:s1   "./run.sh"               About an hour ago   Up About an hour    3000/tcp                                                             s1
f9ce8714cb92        softengheigvd/webapp:s2   "./run.sh"               About an hour ago   Up About an hour    3000/tcp                                                             s2
```





```bash
$ curl -s http://localhost | jq -r
{
  "hello": "world!",
  "ip": "172.16.238.11",
  "host": "s1",
  "tag": "s1",
  "sessionViews": 1,
  "id": "OUgIiV02wq4FmXwH95Y00nXUu7CD5qo1"
}
```

![](assets/img/task-0-01-http-get-localhost.png)

![](assets/img/task-0-02-haproxy-stats-page.png)

**URL du repo** : https://github.com/Callisto88/AIT_Labo4

## Task 1

Updated **Dockerfile** from **webapp**

```dockerfile
# The base image is one of the offical one
FROM node:0.12.2-wheezy

MAINTAINER Cyril de Bourgues <cyril.debourgues@heig-vd.ch>

# Install the required tools to run our webapp and some utils
RUN apt-get update && apt-get -y install wget curl vim && npm install -g bower

# We copy the application and make sure the dependencies are installed before
# other operations. Doing so will reduce the time required to build this image
# as downloading NPM dependencies can be quite long.
COPY app /backend/app
RUN cd /backend/app && npm install && bower install --allow-root

RUN curl -sSLo /tmp/s6.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz \
  && tar xzf /tmp/s6.tar.gz -C / \
  && rm -f /tmp/s6.tar.gz

[...]
```

Updated **Dockerfile** from **ha**

```dockerfile
# Base image is the Official HAProxy
FROM haproxy:1.5

MAINTAINER Cyril de Bourgues <cyril.debourgues@heig-vd.ch>

# Install some tools
# TODO: [HB] Update to install required tool to install NodeJS
RUN apt-get update && apt-get -y install wget curl vim rsyslog

RUN curl -sSLo /tmp/s6.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz \
  && tar xzf /tmp/s6.tar.gz -C / \
  && rm -f /tmp/s6.tar.gz
  
[...]
```

Rebuild de l'image **HAProxy**

```bash
mbp-de-cyril-2:noVagrant cyril$ cd ha/
mbp-de-cyril-2:ha cyril$ docker build -t softengheigvd/ha .
Sending build context to Docker daemon  11.78kB
Step 1/12 : FROM haproxy:1.5
 ---> c502bc6681e3
Step 2/12 : MAINTAINER Cyril de Bourgues <cyril.debourgues@heig-vd.ch>
 ---> Running in 71a9372d8e89
Removing intermediate container 71a9372d8e89
 ---> b83396efab1d
Step 3/12 : RUN apt-get update && apt-get -y install wget curl vim rsyslog
 ---> Running in 8571179e1230
Ign:1 http://cdn-fastly.deb.debian.org/debian stretch InRelease
Get:2 http://cdn-fastly.deb.debian.org/debian stretch-updates InRelease [91.0 kB]
Get:3 http://cdn-fastly.deb.debian.org/debian stretch Release [118 kB]

[...]

Setting up curl (7.52.1-5+deb9u8) ...
Processing triggers for libc-bin (2.24-11+deb9u3) ...
Processing triggers for ca-certificates (20161130+nmu1+deb9u1) ...
Updating certificates in /etc/ssl/certs...
0 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
Removing intermediate container 8571179e1230
 ---> 7fdf7a3d9cf5
Step 4/12 : RUN curl -sSLo /tmp/s6.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz   && tar xzf /tmp/s6.tar.gz -C /   && rm -f /tmp/s6.tar.gz
 ---> Running in b99ec76d17bd
Removing intermediate container b99ec76d17bd
 ---> 693954744608
Step 5/12 : COPY scripts/ /scripts/
 ---> c6582195951c
Step 6/12 : RUN chmod +x /scripts/*.sh
 ---> Running in 842175630b46
Removing intermediate container 842175630b46
 ---> 15e1aedc46d0
Step 7/12 : COPY config/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
 ---> d6c0bd9260da
Step 8/12 : COPY config/rsyslogd.cfg /etc/rsyslog.d/49-haproxy.conf
 ---> c21ffa3dec76
Step 9/12 : RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
 ---> Running in b8317aa3a67e
Removing intermediate container b8317aa3a67e
 ---> 23a97100b84d
Step 10/12 : EXPOSE 80 1936
 ---> Running in 4b9fc3e21e82
Removing intermediate container 4b9fc3e21e82
 ---> 99c72704f4a4
Step 11/12 : ENV ROLE balancer
 ---> Running in 544d28e2646a
Removing intermediate container 544d28e2646a
 ---> 48a7baf80f5e
Step 12/12 : CMD [ "/scripts/run.sh" ]
 ---> Running in af4654d2062d
Removing intermediate container af4654d2062d
 ---> 34bc84c82b9a
Successfully built 34bc84c82b9a
Successfully tagged softengheigvd/ha:latest
mbp-de-cyril-2:ha cyril$
```

Rebuild de **webapp**

```bash
mbp-de-cyril-2:noVagrant cyril$ cd webapp/
mbp-de-cyril-2:webapp cyril$ docker build -t softengheigvd/webapp .
Sending build context to Docker daemon  31.74kB
Step 1/12 : FROM node:0.12.2-wheezy
 ---> 51625719dd87
Step 2/12 : MAINTAINER Cyril de Bourgues <cyril.debourgues@heig-vd.ch>
 ---> Running in 864cf89da2e5
Removing intermediate container 864cf89da2e5
 ---> cb3c6e2bd81a
Step 3/12 : RUN apt-get update && apt-get -y install wget curl vim && npm install -g bower
 ---> Running in a4a5dd987776
Get:1 http://httpredir.debian.org wheezy Release.gpg [2373 B]
Get:2 http://security.debian.org wheezy/updates Release.gpg [1601 B]
Get:3 http://httpredir.debian.org wheezy-updates Release.gpg [1601 B]

[...]

thread-sleep@1.0.4 node_modules/thread-sleep
└── nan@2.11.1
{}
Removing intermediate container 7d9a14716c5b
 ---> b5e869e339eb
Step 6/12 : RUN curl -sSLo /tmp/s6.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz   && tar xzf /tmp/s6.tar.gz -C /   && rm -f /tmp/s6.tar.gz
 ---> Running in 9f3bb7b2a943
Removing intermediate container 9f3bb7b2a943
 ---> 612d77ce8211
Step 7/12 : COPY scripts /scripts/
 ---> 2c83eb0ea8ce
Step 8/12 : RUN chmod +x /scripts/*.sh
 ---> Running in 57041b650bfb
Removing intermediate container 57041b650bfb
 ---> ee7ebdbc3cea
Step 9/12 : RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
 ---> Running in f7daf2e068ce
Removing intermediate container f7daf2e068ce
 ---> 0505e2114360
Step 10/12 : EXPOSE 3000
 ---> Running in 6cc4b86cf42f
Removing intermediate container 6cc4b86cf42f
 ---> 838de156eac9
Step 11/12 : ENV ROLE backend
 ---> Running in 56097c8ffc27
Removing intermediate container 56097c8ffc27
 ---> f8308985744a
Step 12/12 : CMD [ "/scripts/run.sh" ]
 ---> Running in ba127428bf2e
Removing intermediate container ba127428bf2e
 ---> 6651c9c853bf
Successfully built 6651c9c853bf
Successfully tagged softengheigvd/webapp:latest
mbp-de-cyril-2:webapp cyril$
```

Stop containers and restart them

```bash
mbp-de-cyril-2:webapp cyril$ docker run -d --name s1 softengheigvd/webapp
910ba1ee645e6cbaa83d0be3a0155cd4a6c179514b2de98d5e2b648e8f88a2ae

mbp-de-cyril-2:webapp cyril$ docker run -d --name s2 softengheigvd/webapp
289f248b0aa69c5200b4ee2efcc5797c33d73be3a83a8e3691e691678b2273cb

mbp-de-cyril-2:webapp cyril$ docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --link s1 --link s2 --name ha softengheigvd/ha
65480d6e7741a17c715ce828772909d6a6d159fa81991e74c8405e8ec8099907
```



```bash
mbp-de-cyril-2:webapp cyril$ docker ps
CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS                                                                NAMES
65480d6e7741        softengheigvd/ha       "/docker-entrypoint.…"   2 minutes ago       Up 2 minutes        0.0.0.0:80->80/tcp, 0.0.0.0:1936->1936/tcp, 0.0.0.0:9999->9999/tcp   ha
289f248b0aa6        softengheigvd/webapp   "/scripts/run.sh"        3 minutes ago       Up 2 minutes        3000/tcp                                                             s2
910ba1ee645e        softengheigvd/webapp   "/scripts/run.sh"        3 minutes ago       Up 2 minutes        3000/tcp                                                             s1
```





```bash
mbp-de-cyril-2:noVagrant cyril$ mkdir -p ha/services/ha webapp/services/node
mbp-de-cyril-2:noVagrant cyril$ tree -L 3
.
[...]
├── ha
│   ├── Dockerfile
│   ├── config
│   │   ├── haproxy.cfg
│   │   └── rsyslogd.cfg
│   ├── scripts
│   │   └── run.sh
│   └── services
│       └── ha
[...]
└── webapp
    ├── Dockerfile
    ├── app
    │   ├── Gruntfile.js
    │   ├── app
    │   ├── app.js
    │   ├── bower.json
    │   ├── config
    │   ├── package.json
    │   └── public
    ├── scripts
    │   └── run.sh
    └── services
        └── node
```



Copie des scripts dans les sous-répertoires services

```bash
mbp-de-cyril-2:noVagrant cyril$ cp ha/scripts/run.sh ha/services/ha/run && chmod +x ha/services/ha/run

mbp-de-cyril-2:noVagrant cyril$ cp webapp/scripts/run.sh webapp/services/node/run && chmod +x webapp/services/node/run
```



Remplacement du hashbang dans les scripts **run**

Pour **haproxy**

```bash
#!/usr/bin/with-contenv bash
rsyslogd -c5 2>/dev/null
[...]
```

Pour **webapp**

```bash
#!/usr/bin/with-contenv bash
[...]
```



script run.sh mise à jour pour le container **haproxy**

```bash
[...]

RUN curl -sSLo /tmp/s6.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz \
  && tar xzf /tmp/s6.tar.gz -C / \
  && rm -f /tmp/s6.tar.gz

# TODO: [Serf] Install

# TODO: [HB] Install NodeJS

# TODO: [HB] Install Handlebars

# Copy the S6 service and make the run script executable
COPY services/ha /etc/services.d/ha
RUN chmod +x /etc/services.d/ha/run

[...]
```



script run.sh mis à jour pour le container contenant **webapp**

```bash
[...]

RUN curl -sSLo /tmp/s6.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz \
  && tar xzf /tmp/s6.tar.gz -C / \
  && rm -f /tmp/s6.tar.gz

# TODO: [Serf] Install

# Copy the S6 service and make the run script executable
COPY services/node /etc/services.d/node
RUN chmod +x /etc/services.d/node/run

[...]
```



Puis rebuild des deux containers

```bash
mbp-de-cyril-2:ha cyril$ docker build -t softengheigvd/ha .
Sending build context to Docker daemon  13.82kB
Step 1/12 : FROM haproxy:1.5
 ---> c502bc6681e3
```



```bash
mbp-de-cyril-2:webapp cyril$ docker build -t softengheigvd/webapp .
Sending build context to Docker daemon  33.79kB
Step 1/12 : FROM node:0.12.2-wheezy
 ---> 51625719dd87
Step 2/12 : MAINTAINER Cyril de Bourgues <cyril.debourgues@heig-vd.ch>
 ---> Using cache
 ---> cb3c6e2bd81a
```





## Task 2

Ajout des instructions d'installation dans les Dockerfile d'HAProxy et webapp

```bash
[...]

RUN curl -sSLo /tmp/s6.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz \
  && tar xzf /tmp/s6.tar.gz -C / \
  && rm -f /tmp/s6.tar.gz

# Install serf (for decentralized cluster membership: https://www.serf.io/)
RUN mkdir /opt/bin \
    && curl -sSLo /tmp/serf.gz https://releases.hashicorp.com/serf/0.7.0/serf_0.7.0_linux_amd64.zip \
    && gunzip -c /tmp/serf.gz > /opt/bin/serf \
    && chmod 755 /opt/bin/serf \
    && rm -f /tmp/serf.gz

# Copy the S6 service and make the run script executable
COPY services/node /etc/services.d/node
RUN chmod +x /etc/services.d/node/run

[...]
```



Puis rebuild des deux images (ha et webapp)

```bash
mbp-de-cyril-2:noVagrant cyril$ cd ha/
mbp-de-cyril-2:ha cyril$ docker build -t softengheigvd/ha .
[...]
mbp-de-cyril-2:noVagrant cyril$ cd webapp/
mbp-de-cyril-2:ha cyril$ docker build -t softengheigvd/webapp .
[...]
```



Création des répertoires serf pour la gestion des services par S6

```bash
mbp-de-cyril-2:noVagrant cyril$ mkdir ha/services/serf webapp/services/serf
```

Nouvelle structure

```bash
mbp-de-cyril-2:noVagrant cyril$ tree -L 3 ha/ webapp/
ha/
├── Dockerfile
├── config
│   ├── haproxy.cfg
│   └── rsyslogd.cfg
├── scripts
│   └── run.sh
└── services
    ├── ha
    │   └── run
    └── serf
webapp/
├── Dockerfile
├── app
│   ├── Gruntfile.js
│   ├── app
│   │   ├── controllers
│   │   ├── models
│   │   └── views
│   ├── app.js
│   ├── bower.json
│   ├── config
│   │   ├── config.js
│   │   └── express.js
│   ├── package.json
│   └── public
│       └── css
├── scripts
│   └── run.sh
└── services
    ├── node
    │   └── run
    └── serf

17 directories, 14 files
```

Création des fichiers **run**

```bash
mbp-de-cyril-2:noVagrant cyril$ touch ha/services/serf/run && chmod +x ha/services/serf/run

mbp-de-cyril-2:noVagrant cyril$ touch webapp/services/serf/run && chmod +x webapp/services/serf/run
```



*Anyway, in our current solution, there is kind of misconception around the way we create the `Serf` cluster. In the deliverables, describe which problem exists with the current solution based on the previous explanations and remarks. Propose a solution to solve the issue.*

*To make sure that `ha` load balancer can leave and enter the cluster again, we add the `--replay` option. This will make the Serf agent replay the past events and then react to these events. In fact, due to the problem you have to guess, this will probably not be really useful.*



Copie des scripts **run** vers **/etc/services.d/** pour webapp & ha

```dockerfile
[...]

COPY services/serf /etc/services.d/serf
RUN chmod +x /etc/services.d/serf/run

[...]
```



Exposition des ports pour Serf

dans **webapp**

```dockerfile
[...]

# Expose the ports for Serf
EXPOSE 7946 7373

# Expose the web application port
EXPOSE 3000

[...]
```

dans **ha**

```dockerfile
[...]

# Expose the ports for Serf
EXPOSE 7946 7373

# Expose the HA proxy ports
EXPOSE 80 1936

[...]
```



Enfin, rebuild des images, suppression des containers existants puis relance de ceux-ci

```bash
mbp-de-cyril-2:webapp cyril$ docker rm -f ha s1 s2
ha
s1
s2
mbp-de-cyril-2:webapp cyril$
mbp-de-cyril-2:noVagrant cyril$ docker-compose up -d --build --force-recreate
Creating network "novagrant_app_net" with driver "bridge"
Creating s2 ... done
Creating s1 ... done
Creating ha ... done
mbp-de-cyril-2:noVagrant cyril$
mbp-de-cyril-2:noVagrant cyril$ docker ps
CONTAINER ID        IMAGE                     COMMAND                  CREATED             STATUS              PORTS                                                                NAMES
dc49fb453c4c        novagrant_haproxy         "/docker-entrypoint.…"   5 seconds ago       Up 4 seconds        0.0.0.0:80->80/tcp, 0.0.0.0:1936->1936/tcp, 0.0.0.0:9999->9999/tcp   ha
d66b99f8c717        softengheigvd/webapp:s2   "./run.sh"               6 seconds ago       Up 5 seconds        3000/tcp                                                             s2
3c20b7b231d0        softengheigvd/webapp:s1   "./run.sh"               6 seconds ago       Up 5 seconds        3000/tcp                                                             s1
mbp-de-cyril-2:noVagrant cyril$
mbp-de-cyril-2:noVagrant cyril$ curl -s http://localhost | jq -r
{
  "hello": "world!",
  "ip": "172.16.238.11",
  "host": "s1",
  "tag": "s1",
  "sessionViews": 1,
  "id": "PLXBEoeKCqQXDDTvw17vhW2hgfttZXwZ"
}
mbp-de-cyril-2:noVagrant cyril$ curl -s http://localhost | jq -r
{
  "hello": "world!",
  "ip": "172.16.238.12",
  "host": "s2",
  "tag": "s2",
  "sessionViews": 1,
  "id": "tXxATPbO7z7dNN99Mr3f48fbdPFloHM_"
}
mbp-de-cyril-2:noVagrant cyril$ curl -s http://localhost | jq -r
{
  "hello": "world!",
  "ip": "172.16.238.11",
  "host": "s1",
  "tag": "s1",
  "sessionViews": 1,
  "id": "smAB6RtZARs3MzTKEjYDuIgBbEWiTIG1"
}
mbp-de-cyril-2:noVagrant cyril$ curl -s http://localhost | jq -r
{
  "hello": "world!",
  "ip": "172.16.238.12",
  "host": "s2",
  "tag": "s2",
  "sessionViews": 1,
  "id": "st8YK4hngjdJBFmkfnImrDiSDYE8Awu_"
}
mbp-de-cyril-2:noVagrant cyril$
```



```bash
mbp-de-cyril-2:noVagrant cyril$ docker logs s2
Application started
HEAD / 200 16.611 ms - 119
HEAD / 200 5.292 ms - 119
HEAD / 200 3.386 ms - 119
HEAD / 200 2.593 ms - 119
HEAD / 200 3.113 ms - 119
HEAD / 200 2.959 ms - 119
```





## Task 3



## Task 4



## Task 5



## Task 6





## Difficulties

describe the problems you have encountered and



## Conclusion

