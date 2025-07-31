resource "aws_vpc" "myvpc" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_public_myvpc" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"

}

resource "aws_internet_gateway" "gateway" {
    vpc_id = aws_vpc.myvpc.id
    tags = {
        Name = "Gateway"
    }
}

resource "aws_route_table" "route_table" {
    vpc_id = aws_vpc.myvpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gateway.id
    }
    tags = {
        Name = "Route table"
    }
}

resource "aws_route_table_asociation" "asociation" {
    subnet_id = aws_subnet.subnet_public_myvpc.id
    route_table_id = aws_route_table.route_table.id
}

resource "aws_key_pair" "mykey" {
    key_name = "mykey"
    public_key = file("${path.module}/keys/my_key.pub")
}


resource "aws_security_group" "ec2_sg"{
    name = "sg_for_ec2"
    description = "Security group for my instance ec2"
    vpc_id = aws_vpc.myvpc.id
    ingress {
        description = "Allow HTTP protocol"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #In this case I'm not going to use HTTPS
    ingress {
        description = "Allow SSH trafic"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        description = "Allow all outbound traffic"
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "Security group for ec2"
    }
}

resource "aws_instance" "instance" {
    ami = "ami-020cba7c55df1f615" #Ubuntu
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet_public_myvpc.id
    vpc_security_group_ids = [aws_security_group.ec2_sg.id]
    user_data = <<-EOF
                    sudo apt-get update -y
                EOF
    key_name = aws_key_pair.mykey.key_name
    tags = {
        Name = "My instance"
    }
}