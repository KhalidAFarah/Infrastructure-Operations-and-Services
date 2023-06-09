terraform {
  required_providers{
    openstack = {
        source = "terraform-provider-openstack/openstack"
    }
  }
}

provider "openstack" {
  cloud = "openstack"
}

data "openstack_images_image_v2" "ubuntu_22" {
  name = "ubuntu-22.04"
}
data "openstack_images_image_v2" "debian_11" {
  name = "debian-11"
}

# resource "openstack_compute_instance_v2" "mini_instance" {
#     name        = "mini_instance"
#     image_id  = "${data.openstack_images_image_v2.ubuntu_22.id}"#"ubuntu-22.04"
#     flavor_name = "b2.c1r4"
#     key_pair   = "Controller key"

#     network {
#       name = "default"
#     }
    
#     block_device {
#         uuid = "${data.openstack_images_image_v2.ubuntu_22.id}"#"aac74808-9dba-4f49-a530-70a23b4163f3"
#         source_type = "image"
#         destination_type = "volume"
#         volume_size = 10
#         boot_index = 0
#         delete_on_termination = true
#     }
# }
resource "openstack_compute_keypair_v2" "key_pair" {
    name = "subkey"
}

resource "openstack_compute_instance_v2" "sub" {
    name        = "sub"
    image_id  = "${data.openstack_images_image_v2.ubuntu_22.id}"#"ubuntu-22.04"
    flavor_name = "b2.c1r4"
    key_pair   = "Controller key"

    network {
      name = "default"
    }
    
    block_device {
        uuid = "${data.openstack_images_image_v2.ubuntu_22.id}"#"aac74808-9dba-4f49-a530-70a23b4163f3"
        source_type = "image"
        destination_type = "volume"
        volume_size = 10
        boot_index = 0
        delete_on_termination = true
    }

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("~/.ssh/id_rsa")}"
      host        = openstack_compute_instance_v2.sub.access_ip_v4
    }

    provisioner "remote-exec" {
      inline = [
          "sleep 20",
          "echo '${openstack_compute_keypair_v2.key_pair.private_key}' >> ./.ssh/id_rsa",
          "chmod 700 ./.ssh/id_rsa",
          "echo '${openstack_compute_keypair_v2.key_pair.public_key}' >> ./.ssh/id_rsa.pub",
      ]
    }

}

resource "openstack_compute_instance_v2" "psub" {
    name        = "psub"
    image_id  = "${data.openstack_images_image_v2.debian_11.id}"#"debian-11"
    flavor_name = "b2.c1r4"
    key_pair   = "subkey"

    network {
      name = "private"
    }
    
    block_device {
        uuid = "${data.openstack_images_image_v2.debian_11.id}"#"f2ef69eb-2856-4319-95f5-902f43fccef8"
        source_type = "image"
        destination_type = "volume"
        volume_size = 10
        boot_index = 0
        delete_on_termination = true
    }
}
