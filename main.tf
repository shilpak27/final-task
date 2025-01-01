# Configure the AWS provider
provider "aws" {
  region = "us-east-1"  # Replace with the desired AWS region
}

# Create a security group, but only if it doesn't exist
resource "aws_security_group" "allow_all" {
  name        = "allow_all_sgnewthree"
  description = "Security group with all inbound and outbound traffic allowed"

  # Allow all inbound traffic
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ensure that this resource is only created if it doesn't exist already
  lifecycle {
    prevent_destroy = true
  }
}

# Create an SSH key pair, but only if it doesn't exist
resource "aws_key_pair" "my_key" {
  key_name   = "my-ssh-three"
  public_key = file("~/.ssh/id_rsa.pub")  # Ensure you have the key already generated

  lifecycle {
    prevent_destroy = true
  }
}

# Create an EC2 instance, but only if it doesn't exist
resource "aws_instance" "my_instance" {
  ami           = "ami-064519b8c76274859"  # Debian 12 AMI
  instance_type = "t2.micro"                # Adjust the instance type as needed

  # Associate the instance with the security group
  security_groups = [aws_security_group.allow_all.name]

  key_name = aws_key_pair.my_key.key_name  # Key pair for SSH access

  tags = {
    Name = "MyTerraformEC2three"
  }

  # Ensure the instance is only created if it doesn't exist
  lifecycle {
    prevent_destroy = true
  }
}

# Provisioner to write the private IP to Ansible inventory.ini file and add SSH key to known_hosts
resource "null_resource" "add_ssh_key_and_inventory" {
  depends_on = [aws_instance.my_instance]

  provisioner "local-exec" {
    command = <<EOT
      # Wait for instance creation and get the IP addresses
      echo "[web]" > inventory.ini
      echo -n "${aws_instance.my_instance.private_ip}" >> inventory.ini
      echo " ansible_ssh_user=admin" >> inventory.ini  # Change to correct SSH user, if needed (e.g., ubuntu for Ubuntu AMIs)
#      echo "[web:vars]" >> inventory.ini
 #     echo "ansible_ssh_private_key_file=~/.ssh/id_rsa" >> inventory.ini  # Path to your private SSH key

      # Add the EC2 instance's SSH public key to known_hosts to avoid fingerprint prompt
#      ssh-keyscan -H ${aws_instance.my_instance.private_ip} >> ~/.ssh/known_hosts
    EOT
  }
}

# Output the private IP of the instance
output "instance_private_ip" {
  value = aws_instance.my_instance.private_ip
}

# Output the public IP of the instance for use in the known_hosts command
output "instance_public_ip" {
  value = aws_instance.my_instance.public_ip
}
