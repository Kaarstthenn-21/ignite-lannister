# Definicion de las Key para conectarse por SSH
resource "aws_key_pair" "default" {
  key_name   = "vpctestkeypair"
  public_key = ""
  # public_key = file("${var.key_path}")
}

#Definicion del servidor web
resource "aws_instance" "wb" {
  ami                         = var.ami
  instance_type               = "t1.micro"
  key_name                    = aws_key_pair.default.id
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = ["${aws_security_group.sgweb.id}"]
  associate_public_ip_address = true
  source_dest_check           = false
  user_data                   = file("install.sh")

  tags = {
    Name = "webserver"
  }
}

#Definicion de la base de datos dentro de la subnet privada
resource "aws_instance" "db" {
  ami                    = var.ami
  instance_type          = "t1.micro"
  key_name               = aws_key_pair.default.id
  subnet_id              = aws_subnet.private-subnet.id
  vpc_security_group_ids = ["${aws_security_group.sgdb.id}"]
  source_dest_check      = false

  tags = {
    Name = "database"
  }
}
