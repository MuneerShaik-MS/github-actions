
# --- EC2 instance (VPC-friendly) ---
resource "aws_instance" "ec2" {
  subnet_id                   = var.subnet_id
  instance_type               = var.instance_type
  ami                         = data.aws_ami.joindevops.id  
  
  associate_public_ip_address = true

  tags = var.resource_name
  root_block_device {
volume_type = "gp3"
volume_size = 50
delete_on_termination = true
encrypted = false
}
}



# --- Install Docker on RHEL via SSH (null_resource + remote-exec) ---
resource "null_resource" "install_docker" {
  depends_on = [aws_instance.ec2]   # ensure instance is ready

  triggers = {
    instance_id = aws_instance.ec2.id
    # bump this to force re-run if needed
    setup_version = "v1"
  }

  connection {
    type        = "ssh"
    host        = aws_instance.ec2.public_ip
    user        = "ec2-user"                   # RHEL default
    password = "DevOps321"
     # path to your private key
  }

  
 provisioner "file" {
    source      = "install-docker.sh"  # local path
    destination = "/home/ec2-user/install-docker.sh" # remote path
  }

  # Now execute it (optional)
  provisioner "remote-exec" {
    inline = [
      "set -euxo pipefail",
      "sudo chmod +x /home/ec2-user/install-docker.sh",
      "sudo /home/ec2-user/install-docker.sh",
    ]
  }
# provisioner "remote-exec" {
#   inline = [
#     "sudo parted /dev/nvme1n1 --script mklabel gpt",
#     "sudo parted /dev/nvme1n1 --script mkpart primary xfs 0% 100%",
#     "sudo mkfs.xfs -f /dev/nvme1n1p1",
#     "sudo mkdir -p /var/lib/containerd",
#     "sudo mount /dev/nvme1n1p1 /var/lib/containerd",
#     "df -h"
#   ]
# }

}


