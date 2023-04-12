#!bin/bash
docker swarm update --task-history-limit 3

docker network create --driver overlay --attachable site_ingress

docker compose -f ./mongo.yaml --env-file ./.env pull
docker stack deploy -c <(docker-compose -f ./mongo.yaml --env-file ./.env config) mongo

docker compose -f ./ctl.yaml --env-file ./.env pull
docker stack deploy -c <(docker-compose -f ./ctl.yaml --env-file ./.env config) ctl

docker compose -f ./gateway.yaml --env-file ./.env pull
docker stack deploy -c <(docker-compose -f ./gateway.yaml --env-file ./.env config) gateway

docker compose -p site -f ./site.yaml pull
docker compose -p site -f ./site.yaml up -d

# Auth with PAT in file
