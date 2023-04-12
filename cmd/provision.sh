#!bin/bash

# echo [ OK  ] with green color in ok text
# echo -e "\e[32m[ OK  ]\e[0m"
# echo [ SKIPPED  ] with yellow color in skipped text
# echo -e "\e[33m[ SKIPPED  ]\e[0m"
# hide all outout from command
# Check docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin is installed
if ! command -v docker &> /dev/null
then
  echo "        Started Installing Docker"
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
  echo -e "\e[32m[ OK  ]\e[0m Finished Installing Docker"
else
  echo -e "\e[33m[ SKIPPED  ]\e[0m Docker is already installed"
fi

# Check docker swarm is initialized
if ! docker info | grep -q "Swarm: active"
then
  echo "        Started Initializing Docker Swarm"
  docker swarm init
  echo -e "\e[32m[ OK  ]\e[0m Finished Initializing Docker Swarm"
else
  echo -e "\e[33m[ SKIPPED  ]\e[0m Docker Swarm is already initialized"
fi

# sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# sudo chmod +x /usr/local/bin/docker-compose

# docker swarm init

# bash ./setup-public.sh