#!bin/bash

# Function to echo [ OK  ] with green color in ok text
ok() {
  echo -e "\e[32m[ OK  ]\e[0m      $1"
}

# Function to echo [ SKIPPED  ] with yellow color in skipped text
skipped() {
  echo -e "\e[33m[ SKIPPED  ]\e[0m $1"
}

# Function to echo [ FAILED  ] with red color in failed text
failed() {
  echo -e "\e[31m[ FAILED  ]\e[0m  $1"
}

# Function to echo "tab" with 8 spaces
info() {
  echo "             $1"
}
# Check run script with bash only
if [ "$BASH_VERSION" = "" ]
then
  failed "Please run with bash"
  exit
fi

# Check if user is root
if [ "$EUID" -ne 0 ]
  then failed "Please run as root"
  exit
fi

# Change directory to script directory
cd "$(dirname "$0")"

# Check if ./.env file exists
info "Started Checking .env file"
if [ ! -f ./.env ]
then
  failed "Please create a .env file in the root directory"
  exit
else
  ok "Found .env file"
fi

# Check docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin is installed
info "Started Installing Docker"
if ! command -v docker &> /dev/null
then
  sudo apt-get update -y
  sudo apt-get install \
      ca-certificates \
      curl \
      gnupg -y

  sudo mkdir -m 0755 -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
  sudo apt-get update -y
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
  ok "Finished Installing Docker"
else
  skipped "Docker is already installed"
fi


# Check docker-compose is installed
info "Started Installing Docker-Compose"
if ! command -v docker-compose &> /dev/null
then
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  ok "Finished Installing Docker-Compose"
else
  skipped "Docker-Compose is already installed"
fi

# Check docker swarm is initialized
info "Started Initializing Docker Swarm"
if ! docker info | grep -q "Swarm: active"
then
  docker swarm init
  ok "Finished Initializing Docker Swarm"
else
  skipped "Docker Swarm is already initialized"
fi

# Check docker swarm task limit is not 3
info "Started Updating Docker Swarm Task Limit"
if ! docker info | grep -q "   Task History Retention Limit: 3"
then
  docker swarm update --task-history-limit 3
  ok "Finished Updating Docker Swarm Task Limit"
else
  skipped "Docker Swarm Task Limit is already 3"
fi

# Check docker network site_ingress is created
info "Started Creating Docker Network site_ingress"
if ! docker network ls | grep -q "site_ingress"
then
  docker network create --driver overlay --attachable site_ingress
  ok "Finished Creating Docker Network site_ingress"
else
  skipped "Docker Network site_ingress is already created"
fi

# Deploy mongo stack
info "Started Deploying Mongo Stack"
# Check permissions of ./docker/data/mongo_primary is 1001
if [ "$(stat -c '%u' ./docker/data/mongo_primary)" -ne 1001 ]
then
  chown -R 1001 ./docker/data/mongo_primary
  ok "Changed Permissions of ./docker/data/mongo_primary to 1001"
else
  skipped "Permissions of ./docker/data/mongo_primary is already 1001"
fi
docker compose -f ./docker/mongo.yaml --env-file ./.env pull
docker stack deploy -c <(docker-compose -f ./docker/mongo.yaml --env-file ./.env config) mongo
ok "Finished Deploying Mongo Stack"

# Deploy ctl stack
info "Started Deploying Ctl Stack"
docker compose -f ./docker/ctl.yaml --env-file ./.env pull
docker stack deploy -c <(docker-compose -f ./docker/ctl.yaml --env-file ./.env config) ctl
ok "Finished Deploying Ctl Stack"

# Deploy gateway stack
info "Started Deploying Gateway Stack"
docker compose -f ./docker/gateway.yaml --env-file ./.env pull
docker stack deploy -c <(docker-compose -f ./docker/gateway.yaml --env-file ./.env config) gateway
ok "Finished Deploying Gateway Stack"

# Deploy site compose
info "Started Deploying Site Stack"
docker compose -p site -f ./docker/site.yaml pull
docker compose -p site -f ./docker/site.yaml up -d
ok "Finished Deploying Site Stack"

# Check if --with-private is passed
if [ "$1" = "--with-private" ]
then
  # Check have site.crt site.key in ./certs
  info "Started Checking Certs"
  if [ ! -f ./certs/site.crt ] || [ ! -f ./certs/site.key ]
  then
    failed "Please create site.crt and site.key in the certs directory"
    exit
  else
    ok "Found site.crt and site.key in the certs directory"
  fi
  # Check ghcr.io is logged in
  # Check logged in by docker login ghcr.io if result is not Login Succeeded then ask user to input email and personal access token
  if ! docker login ghcr.io | grep -q "Login Succeeded"
  then
    # Ask user to input email
    read -p 'Email: ' email
    # Ask user to input personal access token
    # Receive input from user and store it in variable
    read -p 'Pull Secret: ' pull_secret
    # Check if pull_secret is empty
    if [ -z "$pull_secret" ]
    then
      failed "Pull Secret is empty"
      exit
    fi
    # Login ghcr.io with pull_secret
    docker login ghcr.io -u "$email" -p "$pull_secret"
  else
    skipped "ghcr.io is already logged in"
  fi

  info "Started Deploying Core Stack"
  docker compose -f ./docker/core.yaml --env-file ./.env pull
  docker stack deploy -c <(docker-compose -f ./docker/core.yaml --env-file ./.env config) core --with-registry-auth
  ok "Finished Deploying Core Stack"

  info "Started Deploying Auth Stack"
  docker compose -f ./docker/auth.yaml --env-file ./.env pull
  docker stack deploy -c <(docker-compose -f ./docker/auth.yaml --env-file ./.env config) auth --with-registry-auth
  ok "Finished Deploying Auth Stack"

  info "Started Deploying EDC Stack"
  docker compose -f ./docker/edc.yaml --env-file ./.env pull
  docker stack deploy -c <(docker-compose -f ./docker/edc.yaml --env-file ./.env config) edc --with-registry-auth
  ok "Finished Deploying EDC Stack"
  
else
  skipped "Deploy Private Images"
fi


# Print command output with same 3 lines
