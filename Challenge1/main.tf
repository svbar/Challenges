provider "aws" {
  region = "eu-central-1"
  
  access_key = var.access_key
  secret_key = var.secret_key
}

#provision app vpc to be used for all three servers
resource "aws_vpc" "app_vpc" {
  cidr_block           = "192.168.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "3 Tier App VPC"
  }
}

# create internet gateway because it non default VPC
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
}

# aAdding DHCP Options
resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]
}

# Associate dhcp with our vpc
resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.app_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dns_resolver.id
}

#default route table 
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.app_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }
}


#provision of  web tier1 subnet
resource "aws_subnet" "web_subnet" {
  vpc_id     = aws_vpc.app_vpc.id
  cidr_block = "192.168.10.0/24"
  
  tags = {
    Name = "webtier subnet"
  }
  depends_on = [aws_vpc_dhcp_options_association.dns_resolver]
}


#Security Group for Tier-1 server

resource "aws_security_group" "webtier1" {
  name = "security-group-t1"
  vpc_id = aws_vpc.app_vpc.id
  subnet_id = aws_subnet.web_subnet.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
      }

}


# AWS VM Provision - Presentation Tier1

resource "aws_instance" "tier2web" {
  ami           = "ami-0b6d8a6db0c665fb7"
  instance_type = "t2.micro"
  vpc_security_group_ids = "aws_security_group.webtier1.id"


	tags = {
    Name = "tier-1-web"
  }


user_data = <<-EOF
              #!/bin/bash
              sudo apt-get install apache2 &&
              sudo systemctl start apache2
              EOF

output "public_ip" {
  value       = aws_instance.tier2app.public_ip
  description = "The public IP of the web server"

}


############################################### 2 ##################################
#Security group for App tier server
resource "aws_security_group" "apptier2" {
  name = "security-group-t2"
  vpc_id = aws_vpc.app_vpc.id
  subnet_id = aws_subnet.app_subnet.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["192.168.10.0/24"]
    }

    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/24"]
    }

    egress {
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
      }

}

#provision of  app tier2 subnet
resource "aws_subnet" "app_subnet" {
  vpc_id     = aws_vpc.app_vpc.id
  cidr_block = "192.168.20.0/24"
  
  tags = {
    Name = "apptier subnet"
  }
depends_on = [aws_vpc_dhcp_options_association.dns_resolver]
}

# AWS VM Provision  - Application layer

resource "aws_instance" "tier2app" {
  ami           = "ami-0b6d8a6db0c665fb7"
  instance_type = "t2.micro"
  vpc_security_group_ids = "aws_security_group.apptier2.id"


	tags = {
    Name = "tier-1-web"
  }



user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install default-jdk
              sudo useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat
              wget http://www-eu.apache.org/dist/tomcat/tomcat-9/v9.0.27/bin/apache-tomcat-9.0.27.tar.gz -P /tmp
              sudo tar xf /tmp/apache-tomcat-9*.tar.gz -C /opt/tomcat
              sudo ln -s /opt/tomcat/apache-tomcat-9.0.27 /opt/tomcat/latest
              sudo chown -RH tomcat: /opt/tomcat/latest
              sudo sh -c 'chmod +x /opt/tomcat/latest/bin/*.sh
              sudo systemctl start tomcat
              EOF


output "public_ip" {
  value       = aws_instance.tier2app.private_ip
  description = "The public IP of the web server"
}
}

################################################# 3###############################
# Provision of security group for DB instance

resource "aws_security_group" "db" {
  name = "security-group-t3"
  vpc_id = aws_vpc.app_vpc.id
  subnet_id = aws_subnet.app_subnet.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["192.168.20.0/24"]
    }
ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/24"]
    }
    egress {
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
      }

}

resource "aws_subnet" "db_subnet" {
  vpc_id     = aws_vpc.app_vpc.id
  cidr_block = "192.168.30.0/24"
  
  tags = {
    Name = "DB tier subnet"
  }
}

### subnet group for AWS RDS 
resource "aws_db_subnet_group" "dbsubnet" {
  name       = "app db_subnet"
  subnet_ids = [aws_subnet.db_subnet.id]
}

# Provision of DB Instance
resource "aws_db_instance" "appdb" {
  identifier             = "appdb"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  engine                 = "mysql"
  name                   = "app3_db"
  password               = var.db_password
  username               = var.db_user
  engine_version         = "5.7.00"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.dbsubnet.name
  vpc_security_group_ids = [aws_security_group.db.id]

  }
}


## management Server for managing servers
resource "aws_instance" "tier2web" {
  ami           = "ami-0b6d8a6db0c665fb7"
  instance_type = "t2.micro"
  vpc_security_group_ids = "aws_security_group.webtier1.id"


	tags = {
    Name = "Mgmt server"
  }



output "public_ip" {
  value       = aws_instance.tier2app.public_ip
  description = "The public IP of the web server"

}

resource "aws_security_group" "mgmt" {
  name = "security-group-mgmt"
  vpc_id = aws_vpc.app_vpc.id
  subnet_id = aws_subnet.web_subnet.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["192.168.0.0/24"]
      }

}
