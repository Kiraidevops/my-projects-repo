#root/variables.tf

variable "aws_region" {
  default = "us-east-2"
}

# in tf.vars
variable "access_ip" {
  type = string
}

# --- database ---
variable "dbname" {
  type = string
}
variable "dbuser" {
  type = string
  sensitive = true
}
variable "dbpassword" {
  type = string
  sensitive = true
}

variable "kirai_public_key" {
  sensitive = true
}