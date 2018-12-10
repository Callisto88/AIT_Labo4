# AIT - Labo 4

[TOC]

## Introduction

An introduction describing briefly the lab



## Setup

https://github.com/Callisto88/AIT_Labo4



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



## Task 1



## Task 2



## Task 3



## Task 4



## Task 5



## Task 6





## Difficulties

describe the problems you have encountered and



## Conclusion

