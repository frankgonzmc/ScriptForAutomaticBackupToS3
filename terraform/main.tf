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

#IAM ROLE AND ACCESS FROM EC2
resource "aws_iam_role" "ec2_role"{
    name = "ec2_backup_role"
    assume_role_policy = jsondecode ({
        Version = "2012-10.17"
        Statement = [{
            Effect = "Allow",
            Principal = {
                Service = "ec2.amazonaws.com"
            },
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "s3_access"{
    role = aws_iam_role.ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile"{
    name = "ec2_backup_instance_profile"
    role = aws_iam_role.ec2_role.name
}
###

resource "aws_instance" "instance" {
    ami = "ami-020cba7c55df1f615" #Ubuntu
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet_public_myvpc.id
    vpc_security_group_ids = [aws_security_group.ec2_sg.id]
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    user_data = <<-EOF
                    !#/bin/bash
                    sudo apt-get update -y
                    mkdir -p cont
                    echo "Esto es un ejemplo" > /home/ubuntu/cont/file.txt
                    echo "Esto es un ejemplo2" > /home/ubuntu/cont/file2.txt
                    echo "Esto es un ejemplo3" > /home/ubuntu/cont/file3.txt
                    #Create the script of the backup from terraform
                    cat > /home/ubuntu/backup.sh << 'EOL'
                    ${file("${path.module}/script.sh")}
                    EOL
                    #Give permissions
                    chmod +x /home/ubuntu/backup.sh
                    #Configure cron to execute the backup every 2 minutes
                    (crontab -l 2>/dev/null; echo "*/2 * * * * /home/ubuntu/backup.sh") | crontab -
                EOF
    key_name = aws_key_pair.mykey.key_name
    tags = {
        Name = "My instance"
    }
}

resource "aws_s3" "bucket_backup" {

}