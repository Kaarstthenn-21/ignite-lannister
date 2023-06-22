# Definicion de proveedor, en nuestro caso AWS
provider "aws" {
  region = "${var.aws_region}"
}