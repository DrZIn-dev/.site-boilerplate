#!bin/bash
# echo with same pad start size with 16 spaces
echo "                $1"
# echo [ OK  ] with green color in ok text
echo -e "\e[32m[ OK  ]\e[0m"
# echo [ SKIPPED  ] with yellow color in skipped text
echo -e "\e[33m[ SKIPPED  ]\e[0m"
# echo [ FAILED  ] with red color in failed text
echo -e "\e[31m[ FAILED  ]\e[0m"
# echo "tab" with 8 spaces in info text
echo "        "

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

# Check if user is root
if [ "$EUID" -ne 0 ]
  then failed "Please run as root"
  exit
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