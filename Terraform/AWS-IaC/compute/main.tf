# ---- compute/main.tf ----

data "aws_ami" "server_ami" {
  most_recent      = true
  owners           = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] # * for latest date
  }
}

resource "random_id" "kirai_node_id" {
  byte_length = 2
  count = var.instance_count
}

resource "aws_key_pair" "kirai_pc_aut" {
  key_name = var.key_name
  public_key = var.pub_key
}
resource "aws_instance" "kirai_node" {
  count = var.instance_count
  instance_type = var.instance_type
  ami = data.aws_ami.server_ami.id
  tags = {
    Name = "kirai_node-${random_id.kirai_node_id[count.index].dec}"
  }

  key_name = aws_key_pair.kirai_pc_aut.id
  vpc_security_group_ids = var.public_sg
  subnet_id = var.public_subnets[count.index]
  user_data = templatefile(var.user_data_path, 
       {
        nodename = "kirai_node-${random_id.kirai_node_id[count.index].dec}"
        db_endpoint = var.db_endpoint
        dbuser = var.dbuser
        dbpass = var.dbpassword
        dbname = var.dbname
       }
    )
    root_block_device {
        volume_size = var.vol_size
     }
}
