#!/bin/bash

set -e


export \
STACK_NAME=traefik-consul \
# 3 or 5, not more, if just one node is docker swarm mode, set 0
CONSUL_REPLICAS=3 \
# the value number is equal to the count of swarm mode managers.
# if just have one manager node, set 1
TRAEFIK_REPLICAS=3 \
# id of the current manager node
NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')

while read -r var;do
    export $var
done < <(grep -Ev '^#|^$' .env)


docker network create --driver=overlay $TRAEFIK_NETWORK

docker node update --label-add ${STACK_NAME}.consul-data-leader=true $NODE_ID

sed -i "s/traefik-public/$TRAEFIK_NETWORK/" traefik.yml
docker stack deploy -c traefik.yml $STACK_NAME


echo "Next please put your domain certs in consul as follows:
docker container exec -it traefik-consul_consul-leader... consul kv put traefik/tls/certificates/yourdomain/certFile  "your cert content"
docker container exec -it traefik-consul_consul-leader... consul kv put traefik/tls/certificates/yourdomain/keyFile  "your key content"

Then access follows in browser:
https://traefik.your-base-domain
https://consul.your-base-domain
"