# --- vpc/main.tf 
  
data "aws_availability_zones" "available" {}

resource "random_shuffle" "az_list" {
  input = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

resource "random_integer" "random" {
  min = 1
  max = 100
}

resource "aws_vpc" "kirai_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "kirai_vpc-${random_integer.random.id}"
    }
  #needed for changing vpc,  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "kirai_public" {
  count = var.public_sn_count
  vpc_id = aws_vpc.kirai_vpc.id
  cidr_block = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "kirai_public_${count.index + 1}"
  }
}

resource "aws_route_table_association" "kirai_public_assoc" {
  count = var.public_sn_count
  subnet_id = aws_subnet.kirai_public.*.id[count.index]
  route_table_id = aws_route_table.kirai_public_rt.id
}

resource "aws_subnet" "kirai_private" {
  count = var.private_sn_count
  vpc_id = aws_vpc.kirai_vpc.id
  cidr_block = var.private_cidrs[count.index]  
  map_public_ip_on_launch = false #not needed default=false
  availability_zone = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "kirai_private_${count.index + 1}"
  }
}


resource "aws_internet_gateway" "kirai_internet_gateway" {
  vpc_id = aws_vpc.kirai_vpc.id
  tags = {
    Name = "kirai_igw"
  }
}

resource "aws_route_table" "kirai_public_rt" {
  vpc_id = aws_vpc.kirai_vpc.id
  tags = {
    Name = "kirai_public"
  }
}

resource "aws_route" "default_route" {
  route_table_id = aws_route_table.kirai_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.kirai_internet_gateway.id
}
# default route table created by vpc, can be used for private subnets  
resource "aws_default_route_table" "kirai_private_rt" { 
  default_route_table_id = aws_vpc.kirai_vpc.default_route_table_id

  tags = {
    Name = "kirai_private"
  }
}

########################## sg #####################
resource "aws_security_group" "kirai_public_sg" {
  name = "public_sg"
  description = "SG-public access"
  vpc_id = aws_vpc.kirai_vpc.id
  ingress {
    description = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.access_ip] #in tf.vars
  }
  ingress {
    description = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] 
  }
   ingress {
    description = "HTTP1"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] 
  }
  ingress {
    description = "HTTP2"
    from_port        = 8000
    to_port          = 8000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] 
  }
  egress  {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "kirai_private_sg" {
  name = "private-sg"
  description = "SG-private access"
  vpc_id = aws_vpc.kirai_vpc.id
  ingress {
    description = "MYSQL"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = [var.access_ip] #in tf.vars
  }
}

resource "aws_db_subnet_group" "kirai_rds_subnetgroup" {
  count = var.db_subnet_group == true ? 1 : 0
  name = "kirai_rds_subnetgroup"
  subnet_ids = aws_subnet.kirai_private.*.id
  tags = {
    Name = "kirai_rds_sng"
  }
}