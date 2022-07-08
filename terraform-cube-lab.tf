provider "aws" {
  region     = "eu-central-1"
  access_key = ""
  secret_key = ""
}

# Создаем отдельную VPC как мы делали прошлый раз через веб интерфейс
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

resource "aws_vpc" "actpro-vpc" {
     cidr_block = "10.0.0.0/16"
      tags = {
        Name = "actpro-net"
  }
}

# Создам две подсети публичную и приватную
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

resource "aws_subnet" "front-end-net" {
  vpc_id     = aws_vpc.actpro-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public-net"
  }
}

resource "aws_subnet" "back-end-net" {
  vpc_id     = aws_vpc.actpro-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private-net"
  }
}

# Создать еще одну сеть, а потом удалить ее - показать как удаляются ресурсы


# Создаем маршрутизатор - Internet GW
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway

resource "aws_internet_gateway" "actpro-gw" {
  vpc_id = aws_vpc.actpro-vpc.id

  tags = {
    Name = "actpro-gw"
  }
}

# Создаем таблицу маршрутизации
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table


resource "aws_route_table" "actpro-rt" {
  vpc_id = aws_vpc.actpro-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.actpro-gw.id
  } 

  tags = {
    Name = "actpro-rt-front"
  }
}

# Присоединение сети Front (с доступом в интернет) к нашей таблице маршрутизации
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association

resource "aws_route_table_association" "a-front-net" {
  subnet_id      = aws_subnet.front-end-net.id
  route_table_id = aws_route_table.actpro-rt.id
}
/*
# Создаем таблицу маршрутизации для NAT
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table

resource "aws_route_table" "actpro-rt-nat" {
  vpc_id = aws_vpc.actpro-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.actpor-nat-gateway.id
  } 

  tags = {
    Name = "actpro-rt-back"
  }
}

# Присоединение сети Back (без доступа в интернет) к нашей таблице маршрутизации
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association

resource "aws_route_table_association" "a-back-net" {
  subnet_id      = aws_subnet.back-end-net.id
  route_table_id = aws_route_table.actpro-rt-nat.id
}

# Создаем NAT Gateway
# Выделяем белый ип для него
resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "actpor-nat-gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id = aws_subnet.front-end-net.id
  tags = {
    "Name" = "actpro nat gateway"
  }
}
*/

# Создаем Security Groups
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

resource "aws_security_group" "ansible-sg" {
  name        = "for ansible"
  description = "allow 22 for ssh traffic"
  vpc_id      = aws_vpc.actpro-vpc.id

  ingress {
    description      = "ssh from vpc"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible connection"
  }
}

resource "aws_security_group" "master_node-sg" {
  name        = "master node"
  description = "allow ports from list for control plane"
  vpc_id      = aws_vpc.actpro-vpc.id

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
 ingress {
    description      = "Kubernetes API server"
    from_port        = 6443
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "etcd server client API"
    from_port        = 2379
    to_port          = 2380
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "Kubelet API"
    from_port        = 10250
    to_port          = 10250
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "kube-scheduler"
    from_port        = 10259
    to_port          = 10259
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
    ingress {
    description      = "kube-controller-manager"
    from_port        = 10257
    to_port          = 10257
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "master node"
  }
}

resource "aws_security_group" "worker_node-sg" {
  name        = "worker node"
  description = "allow ports from list for worker node components"
  vpc_id      = aws_vpc.actpro-vpc.id

  ingress {
    description      = ""
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Kubelet API"
    from_port        = 10250
    to_port          = 10250
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "NodePort Services"
    from_port        = 30000
    to_port          = 32767
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "worker node"
  }
}
# Добавляем инстанс
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#network-and-credit-specification-example
# Запрашиваем при помощи data образ с которого будем разворачивать инстанс 

data "aws_ami" "ubuntu-latest" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical 
}

# Создаем новую пару ключей EC2 > Key pairs > New

resource "aws_instance" "ansible-server" {
  ami           = data.aws_ami.ubuntu-latest.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.front-end-net.id
  vpc_security_group_ids = [aws_security_group.ansible-sg.id]
  associate_public_ip_address = true

  key_name = "terraform-key"
  

  tags = {
    Name = "ansible-server"
  }
}

resource "aws_instance" "master-server" {
  ami           = data.aws_ami.ubuntu-latest.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.front-end-net.id
  vpc_security_group_ids = [aws_security_group.master_node-sg.id]
  associate_public_ip_address = true

  key_name = "terraform-key"
  

  tags = {
    Name = "master-server"
  }
}

resource "aws_instance" "worker-node-1" {
  ami           = data.aws_ami.ubuntu-latest.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.front-end-net.id
  vpc_security_group_ids = [aws_security_group.worker_node-sg.id]
  associate_public_ip_address = true

  key_name = "terraform-key"
  

  tags = {
    Name = "worker-node-1"
  }
}

resource "aws_instance" "worker-node-2" {
  ami           = data.aws_ami.ubuntu-latest.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.front-end-net.id
  vpc_security_group_ids = [aws_security_group.worker_node-sg.id]
  associate_public_ip_address = true

  key_name = "terraform-key"
  

  tags = {
    Name = "worker-node-2"
  }
}

resource "aws_instance" "worker-node-3" {
  ami           = data.aws_ami.ubuntu-latest.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.front-end-net.id
  vpc_security_group_ids = [aws_security_group.worker_node-sg.id]
  associate_public_ip_address = true

  key_name = "terraform-key"
  

  tags = {
    Name = "worker-node-3"
  }
}
# resource "aws_instance" "gitlab-runner-shell" {
#   ami           = data.aws_ami.ubuntu-latest.id
#   instance_type = "t2.micro"
#   subnet_id = aws_subnet.front-end-net.id
#   vpc_security_group_ids = [aws_security_group.actpro-sg.id]
#   associate_public_ip_address = true

#   key_name = "terraform-key"
  

#   tags = {
#     Name = "gitlab-runner-shell"
#   }
# }

# resource "aws_instance" "prod-server" {
#   ami           = data.aws_ami.ubuntu-latest.id
#   instance_type = "t2.micro"
#   subnet_id = aws_subnet.front-end-net.id
#   vpc_security_group_ids = [aws_security_group.actpro-sg.id]
#   associate_public_ip_address = true

#   key_name = "terraform-key"
  

#   tags = {
#     Name = "prod-server"
#   }
# }


# resource "aws_instance" "ansible-client-2" {
#   ami           = data.aws_ami.ubuntu-latest.id
#   instance_type = "t2.micro"
#   subnet_id = aws_subnet.front-end-net.id
#   vpc_security_group_ids = [aws_security_group.actpro-sg.id]
#   associate_public_ip_address = true

#   key_name = "terraform-key"
  

#   tags = {
#     Name = "client-2"
#   }
# }

/*
# Создаем Security Groups for backend

resource "aws_security_group" "actpro-sg-backend" {
  name        = "ssh-db"
  description = "allow 22 and 80 ports traffic"
  vpc_id      = aws_vpc.actpro-vpc.id

  ingress {
    description      = "ssh from vpc"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "web from vpc"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-db-sg"
  }
}


# Создаем инстанс в сети back 

resource "aws_instance" "web-server-back" {
  ami           = data.aws_ami.ubuntu-latest.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.back-end-net.id
  vpc_security_group_ids = [aws_security_group.actpro-sg-backend.id]
  #associate_public_ip_address = true

  key_name = "terraform-key"
  

  tags = {
    Name = "web-server-back"
  }
}
*/
# Выведем публичный IP нашего инстанса

# output "ec2_public_ip_ansible" {
#   value = aws_instance.ansible-server.public_ip
# }

# output "ec2_public_ip_gitlab-runner-shell" {
#   value = aws_instance.gitlab-runner-shell.public_ip
# }

# output "ec2_public_ip_client-2" {
#   value = aws_instance.ansible-client-2.public_ip
# }



