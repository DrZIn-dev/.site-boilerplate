#!bin/bash

# Function to echo [ OK  ] with green color in ok text
ok() {
  echo -e "\e[32m[OK]\e[0m      $1"
}

# Function to echo [ SKIPPED  ] with yellow color in skipped text
skipped() {
  echo -e "\e[33m[SKIPPED]\e[0m $1"
}

# Function to echo [ FAILED  ] with red color in failed text
failed() {
  echo -e "\e[31m[FAILED]\e[0m  $1"
}

# Function to echo "tab" with 8 spaces
info() {
  echo "          $1"
}
# Check run script with bash only
if [ "$BASH_VERSION" = "" ]
then
  failed "Please run with bash"
  exit
else
  ok "Running with bash"
fi

# Check if user is root
if [ "$EUID" -ne 0 ]
  then failed "Please run as root"
  exit
else
  ok "Running as root"
fi

# Change directory to script directory
cd "$(dirname "$0")"

info "Started Checking .env file"
if [ ! -f $(pwd)/.env ]
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
# Check docker is enabled in systemctl
if ! systemctl is-enabled docker | grep -q "enabled"
then
  sudo systemctl enable docker
  ok "Enabled Docker in systemctl"
else
  skipped "Docker is already enabled in systemctl"
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

# Check docker network site_ingress is created
info "Started Creating Docker Network site_ingress"
if ! docker network ls | grep -q "site_ingress"
then
  docker network create --attachable site_ingress
  ok "Finished Creating Docker Network site_ingress"
else
  skipped "Docker Network site_ingress is already created"
fi

info "Started Checking permission $(pwd)/docker/app/data/mongo_primary is 1001"
if [ "$(stat -c '%u' $(pwd)/docker/app/data/mongo_primary)" -ne 1001 ]
then
  chown -R 1001 $(pwd)/docker/app/data/mongo_primary
  ok "Changed Permissions of $(pwd)/docker/app/data/mongo_primary to 1001"
else
  skipped "Permissions of $(pwd)/docker/app/data/mongo_primary is already 1001"
fi

# Deploy ctl stack
info "Started Create Site Compose"
docker-compose --project-directory $(pwd)/docker/site --file $(pwd)/docker/site/docker-compose.yaml pull
docker-compose --project-directory $(pwd)/docker/site --file $(pwd)/docker/site/docker-compose.yaml up -d
ok "Finished Create Site Compose"

# Check if --with-app is passed
if [ "$1" = "--with-app" ]
then
  info "Started Checking Certs"
  if [ ! -f $(pwd)/certs/site.crt ] || [ ! -f $(pwd)/certs/site.key ]
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

  info "Started Deploying App Compose"
  docker-compose --project-directory $(pwd)/docker/app --file $(pwd)/docker/app/docker-compose.yaml pull
  docker-compose --project-directory $(pwd)/docker/app --file $(pwd)/docker/app/docker-compose.yaml up -d
  ok "Finished Deploying App Compose"
  
else
  skipped "Deploy Private Images"
fi


# Print command output with same 3 lines
