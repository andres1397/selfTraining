variable "access" {
    description = "Access-key-for-AWS"
    default = "no_access_key_value_found"  
}

variable "secret" {
    description = "Secret-key-for-AWS"
    default = "no_secret_key_value_found"  
}

provider "aws" {
    region = "us-east-1"
    access_key = var.access	
    secret_key = var.secret
}

resource "aws_vpc" "Main" {
    cidr_block = "192.168.0.0/16"
    enable_dns_hostnames = true
    

    tags = {
        Name = "Main"
    }
  
}

resource "aws_route_table" "Public_Route_Table" {
    vpc_id = aws_vpc.Main.id

    route = [ {
      carrier_gateway_id = ""
      cidr_block = "0.0.0.0/0"
      destination_prefix_list_id = ""
      egress_only_gateway_id = ""
      gateway_id = aws_internet_gateway.igw.id
      instance_id = ""
      ipv6_cidr_block = ""
      local_gateway_id = ""
      nat_gateway_id = ""
      network_interface_id = ""
      transit_gateway_id = ""
      vpc_endpoint_id = ""
      vpc_peering_connection_id = ""
    } ]

    tags = {
      Name = "Public Route Table"
    }
}

resource "aws_route_table_association" "Public_Association" {
    subnet_id = aws_subnet.Public_A.id
    route_table_id = aws_route_table.Public_Route_Table.id
}

resource "aws_route_table" "Private_Route_Table" {
    vpc_id = aws_vpc.Main.id

    route = [ {
      carrier_gateway_id = ""
      cidr_block = "0.0.0.0/0"
      destination_prefix_list_id = ""
      egress_only_gateway_id = ""
      gateway_id = aws_internet_gateway.igw.id
      instance_id = ""
      ipv6_cidr_block = ""
      local_gateway_id = ""
      nat_gateway_id = ""
      network_interface_id = ""
      transit_gateway_id = ""
      vpc_endpoint_id = ""
      vpc_peering_connection_id = ""
    } ]

    tags = {
      Name = "Private Route Table"
    }

}

resource "aws_route_table_association" "Private_Association" {
    subnet_id = aws_subnet.Private_A.id
    route_table_id = aws_route_table.Private_Route_Table.id  
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.Main.id


    tags = {
        Name = "internet_gateway"
    } 
}

resource "aws_subnet" "Public_A" {

    availability_zone = "us-east-1a"
    cidr_block = "192.168.20.0/24"
    map_public_ip_on_launch = true
    
    
    vpc_id = aws_vpc.Main.id    
    tags = {
      Name = "Public_Subnet_A"
    }
  
}

resource "aws_subnet" "Private_A" {

    availability_zone = "us-east-1b"
    cidr_block = "192.168.30.0/24"
    map_public_ip_on_launch = true

    vpc_id = aws_vpc.Main.id

    tags = {
      Name = "Private Subnet A"
    }
  
}

resource "aws_instance" "Web" {
    ami = "ami-0747bdcabd34c712a"
    instance_type = "t2.micro"
    private_ip = "192.168.20.10"
    key_name = "TerraformIntegration"

    tags = {
        Name = "Frontend"
    }

    subnet_id = aws_subnet.Public_A.id
    vpc_security_group_ids = [aws_security_group.Web_Server_Security_Group.id]
  
}

resource "aws_instance" "Api" {

    ami = "ami-0747bdcabd34c712a"
    instance_type = "t2.micro"
    private_ip = "192.168.30.10"
    key_name = "TerraformIntegration"

    tags = {
      Name = "Backend"
    }

    subnet_id = aws_subnet.Private_A.id
    vpc_security_group_ids = [aws_security_group.Api_Server_Security_Group.id]

}

#IP of aws instance copied to a file hosts in local system
resource "local_file" "inventory" {
  filename = "hosts"
  content = <<-EOT
    ${aws_instance.Web.public_ip} Frontend
    ${aws_instance.Api.public_ip} Backend
  EOT
}

resource "aws_security_group" "Web_Server_Security_Group" {
    name = "Web Server Security Group"
    vpc_id = aws_vpc.Main.id

    ingress = [ {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "permit inbound traffic"
      from_port = 0
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      protocol = "-1"
      security_groups = []
      self = false
      to_port = 0
    },

    {
      cidr_blocks = [ "192.168.90.150/32" ]
      description = "permit inbound ssh traffic"
      from_port = 22
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      protocol = "tcp"
      security_groups = []
      self = false
      to_port = 22
    }
    
   ]

    egress = [ {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "permit outbound traffic"
      from_port = 0
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      protocol = "-1"
      security_groups = []
      self = false
      to_port = 0
    } ]

    tags = {
      Name = "Web Server Security Group"
    }

}

resource "aws_security_group" "Api_Server_Security_Group" {
    name = "Api Server Security Group"
    vpc_id = aws_vpc.Main.id

    ingress = [ {
      cidr_blocks = ["0.0.0.0/0"]
      description = "permit traffic to api server"
      from_port = 0
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      protocol = "-1"
      security_groups = []
      self = false
      to_port = 0
    },
    {
      cidr_blocks = [ "192.168.90.150/32" ]
      description = "permit inbound ssh traffic"
      from_port = 22
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      protocol = "tcp"
      security_groups = []
      self = false
      to_port = 22
    }

       ]

    egress = [ {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "permit outbound traffic"
      from_port = 0
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      protocol = "-1"
      security_groups = []
      self = false
      to_port = 0
    } ]

    tags = {
      Name = "Api Server Security Group"
    }
  
}

resource "null_resource" "nullremote1" {
depends_on = [aws_instance.Web] 

#copying and running frontend scripts from local system
provisioner "file" {
    source      = "scripts/front.sh"
    destination = "/home/ubuntu/front.sh"
    
    connection {
      type = "ssh"
      user = "ubuntu"
      host = aws_instance.Web.public_ip
      private_key = "${file("./ssh_auth/TerraformIntegration.pem")}" 
      }
      
    }

provisioner "remote-exec" {
  inline = [
    "sudo chmod +x front.sh",
    "sudo chown root:root front.sh",
    "sudo ./front.sh"
  ]
    
    connection {
      type = "ssh"
      user = "ubuntu"
      host = aws_instance.Web.public_ip
      private_key = "${file("./ssh_auth/TerraformIntegration.pem")}" 
      }
      
    }
}

resource "null_resource" "nullremote2" {
depends_on = [aws_instance.Api] 

#copying and running backend scripts from local system
provisioner "file" {
    source      = "scripts/back.sh"
    destination = "/home/ubuntu/back.sh"
    
    connection {
      type = "ssh"
      user = "ubuntu"
      host = aws_instance.Api.public_ip
      private_key = "${file("./ssh_auth/TerraformIntegration.pem")}" 
      }
      
    }

provisioner "remote-exec" {
  inline = [
    "sudo chmod +x back.sh",
    "sudo chown root:root back.sh",
    "sudo ./back.sh"
  ]
    
    connection {
      type = "ssh"
      user = "ubuntu"
      host = aws_instance.Api.public_ip
      private_key = "${file("./ssh_auth/TerraformIntegration.pem")}" 
      }
      
    }
}