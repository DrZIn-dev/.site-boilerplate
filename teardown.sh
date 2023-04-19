#!bin/bash
docker-compose --project-directory $(pwd)/docker/site --file $(pwd)/docker/site/docker-compose.yaml down -v
docker-compose --project-directory $(pwd)/docker/app --file $(pwd)/docker/app/docker-compose.yaml down -v
