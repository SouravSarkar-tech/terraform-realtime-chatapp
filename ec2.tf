# configured aws provider with proper credentials
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}


# create default vpc if one does not exit
resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "default vpc"
  }
}


# use data source to get all avalablility zones in region (us-east-1)
data "aws_availability_zones" "available_zones" {}


# create default subnet if one does not exit
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags = {
    Name = "default subnet"
  }
}


# create security group for the ec2 instance
resource "aws_security_group" "ec2_security_group" {
  name        = "docker_server_ec2_group"
  description = "allow access on ports 80 and 22"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #accessible from anywhere
  }

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #accessible from anywhere
  }

  ingress {
    description = "app accessible on the port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #accessible from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "docker server sg"
  }
}


# use data source to get a registered amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


# launch the ec2 instance
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "tf-chat-app"

  tags = {
    Name = "docker server"
  }
}


# an empty resource block
resource "null_resource" "name" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/Downloads/tf-chat-app.pem") #same-key-pair as that of ec2 genaratioon
    host        = aws_instance.ec2_instance.public_ip
  }

  # copy the password file for your docker hub account
  # from your computer to the ec2 instance 
  provisioner "file" {
    source      = "~/Downloads/my_password.txt"
    destination = "/home/ec2-user/my_password.txt"
  }

  # copy the dockerfile from your computer to the ec2 instance 
  provisioner "file" {
    source      = "Dockerfile"
    destination = "/home/ec2-user/Dockerfile"
  }

  # copy the build_docker_image.sh from your computer to the ec2 instance 
  provisioner "file" {
    source      = "build-docker-image.sh"
    destination = "/home/ec2-user/build-docker-image.sh"
  }

  provisioner "file" {
    source      = "package.json"
    destination = "/home/ec2-user/package.json"
  }

  provisioner "file" {
    source      = "server.js"
    destination = "/home/ec2-user/server.js"
  }

  provisioner "file" {
    source      = "public"
    destination = "/home/ec2-user/public"
  }

    provisioner "file" {
    source      = "index.html"
    destination = "/home/ec2-user/index.html"
  }

  # set permissions and run the build_docker_image.sh file
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /home/ec2-user/build-docker-image.sh",
      "sh /home/ec2-user/build-docker-image.sh"
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.ec2_instance]
}


# print the url of the container
output "container_url" {
  value = join("", ["http://", aws_instance.ec2_instance.public_dns, ":3000"])
}