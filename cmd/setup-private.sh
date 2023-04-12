#!bin/sh
export CR_PAT=""
echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin

# Pull private app image
docker compose -f ./auth.yaml --env-file ./.env pull
docker stack deploy -c <(docker-compose -f ./auth.yaml --env-file ./.env config) auth --with-registry-auth

# EDC App
docker compose -f ./edc.yaml --env-file ./.env pull
docker stack deploy -c <(docker-compose -f ./edc.yaml --env-file ./.env config) edc --with-registry-auth

docker compose -f ./core.yaml --env-file ./.env pull
docker stack deploy -c <(docker-compose -f ./core.yaml --env-file ./.env config) core --with-registry-auth