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

3. Change directory to .site

   ```shell
   cd .site
   ```

4. Copy .env.example to .env

   > Must edit .env file before run provision.sh

   ```shell
   cp .env.example .env
   ```

5. Run install.sh

   ```shell
   bash /root/.site/install.sh
   ```

   full install with private repo

   ```shell
   bash /root/.site/install.sh --with-private
   ```
