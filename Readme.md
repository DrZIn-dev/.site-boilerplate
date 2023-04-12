# About This Repo

is a boilerplate for setup new site machine.

# Getting Start

1. Change directory to root

   ```shell
   cd ~
   ```

2. Clone this reposity and change name to .site

   ```shell
   git clone https://github.com/DrZIn-dev/.site-boilerplate.git .site
   ```

3. Copy .env.example to .env

   - must change `HOST_NAME`, `JWT_SECRET`

   ```shell
   cp .env.example .env
   ```

4. Change directory to .site

   ```shell
   cd .site
   ```

5. Run provision.sh

   - install docker
   - install docker-compose

   ```shell
   bash provision.sh
   ```

6. Setup public container
   ```shell
   bash setup-public.sh
   ```
