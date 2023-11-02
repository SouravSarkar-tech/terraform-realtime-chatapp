#!/bin/bash

# create a repository to store the docker image in docker hub

# install and configure docker on the ec2 instance
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo systemctl enable docker

sudo chmod 777 /var/run/docker.sock

#install node
sudo yum install -y nodejs 
node -v


#install npm
sudo yum install npm

# create a dockerfile

# build the docker image
sudo docker build -t tf-chat-app .

# login to your docker hub account as to avoid password saving here we are giving it in root folder
cat ~/my_password.txt | sudo docker login --username adityadho --password-stdin

# use the docker tag command to give the image a new name
sudo docker tag tf-chat-app adityadho/terraform-chatapp

# push the image to your docker hub repository
sudo docker push adityadho/terraform-chatapp

# start the container to test the image 
sudo docker run -dp 3000:3000 adityadho/terraform-chatapp

# referances
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-container-image.html
# https://docs.docker.com/get-started/02_our_app/
# https://docs.docker.com/engine/reference/commandline/login/#provide-a-password-using-stdin



