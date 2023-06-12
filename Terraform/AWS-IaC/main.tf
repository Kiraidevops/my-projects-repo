# --- root/main.tf --- 

locals {
  vpc_cidr = "10.123.0.0/16"
}

module "vpc" {
  source = "./vpc"
  vpc_cidr = local.vpc_cidr 
  access_ip = var.access_ip #in tf.vars
  public_sn_count = 2
  private_sn_count = 3
  max_subnets = 20
  ### for private and public subnnets range 
  public_cidrs = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  private_cidrs = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  db_subnet_group = true
}

  module "database" {
  source = "./database"
  db_storage = 10
  db_engine_version = "5.7.41" ##   October 2023 end of support date
  db_instance_class = "db.t2.micro"
  dbname = var.dbname
  dbuser = var.dbuser
  dbpassword = var.dbpassword
  db_identifier = "kirai-db"
  skip_db_snapshot = true
  db_subnet_group_name = module.vpc.db_subnet_group_name[0]
  vpc_security_group_ids = module.vpc.db_security_group
} 
 
 module "loadbalancing" {
  source = "./loadbalacing"
  public_sg = module.vpc.public_sg
  public_subnets = module.vpc.public_subnets
  tg_port = 8000
  tg_protocol = "HTTP"
  tg_vpc_id = module.vpc.vpc_id
  lb_healthy_threshold = 2
  lb_unhealthy_threshold = 2
  lb_timeout = 2
  lb_interval = 30
  listener_port = 8000
  listener_protocol = "HTTP"
}  
 ### k8s ###
module "compute" {
  source = "./compute"
  instance_count = 1
  instance_type = "t3.micro"
  public_sg = module.vpc.public_sg
  public_subnets = module.vpc.public_subnets
  vol_size = 10
  key_name = "kiraikey"
  pub_key = var.kirai_public_key
  user_data_path = "${path.root}/userdata.tpl"
  dbname = var.dbname
  dbuser = var.dbuser
  dbpassword = var.dbpassword
  db_endpoint = module.database.db_endpoint
} 
### jenkins ###
module "compute-1" {
  source = "./compute_1"
  instance_count = 1
  instance_type = "t2.medium"
  public_sg = module.vpc.public_sg
  public_subnets = module.vpc.public_subnets
  vol_size = 10
  key_name = "kiraikey"
  pub_key = var.kirai_public_key
  user_data_path = file("userdata.sh")
}
