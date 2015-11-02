# docker-php52-apache #
Docker project with debian squeeze + php 5.2 + apache 2

## Docker-compose ##
Configure your project with docker-compose
- Copy docker-compose.yml.dist to docker-compose.yml
- Configure docker-compose.yml file

### Directory mapping ###
volumes:
  - {local_source_dir}:{docker_file_system_dir_mapped}

### ssh ###
In order to connect to your docker instance:
- Create a ssh public key on the machine that host the docker instance
- Copy the content of ~/.ssh/id_rsa.pub to your docker-compose.yml in the SSH_KEY constant

ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub

environment:
  SSH_KEY: "Put text of ~/.ssh/id_rsa.pub content here !"

## Run ##

docker build project
docker up project
