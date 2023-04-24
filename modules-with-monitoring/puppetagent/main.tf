terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}
provider "openstack" {
  cloud = var.chosen_provider
}

data "openstack_images_image_v2" "name" {
  name = var.image_name
  provider = openstack
}

data "openstack_compute_keypair_v2" "laptop" {
  name = "KF-Laptop-key"
}

resource "openstack_compute_instance_v2" "puppetagent" {
  provider = openstack
  name        = "${var.name}-${count.index}"
  count       = var.number_of_instances
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = var.key_pair_name
  network {
    name = var.network_name
  }
  security_groups = var.security_groups
  
  connection {
    type        = "ssh"
    user        = var.user
    private_key = var.private_key
    host        = self.access_ip_v4
  }

  provisioner "file" {
    source      = "./logstash.conf"
    destination = "./logstash.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 20",
      "echo \"${data.openstack_compute_keypair_v2.laptop.public_key}\" >> ~/.ssh/authorized_keys",
      # "sudo apt update -y",
      # "curl -LO https://apt.puppet.com/puppet7-release-focal.deb",
      # "sudo dpkg -i ./puppet7-release-focal.deb",
      # "sudo apt update -y",
      # "sudo apt-get install puppet-agent -y",
      # "sudo bash -c 'echo -e \"[main]\ncertname=www.${replace(self.name, "_", "")}.openstacklocal\nserver=www.${replace(var.puppetmaster_name, "_", "")}.openstacklocal\nruninterval=${var.runinterval}\" >> /etc/puppetlabs/puppet/puppet.conf'",
      # "sudo bash -c 'echo -e \"${var.puppetmaster_ip} www.${replace(var.puppetmaster_name, "_", "")}.openstacklocal ${replace(var.puppetmaster_name, "_", "")}\" >> /etc/hosts'",
      # "sudo bash -c 'echo -e \"${self.access_ip_v4} www.${self.name}.openstacklocal ${self.name}\" >> /etc/hosts'",
      # "sudo systemctl start puppet",
      # "sudo /opt/puppetlabs/puppet/bin/puppet agent",
      # "echo 'done'"
    "sudo apt-get -y update && sudo apt-get -y install default-jre",
    "sudo apt-get -y update && sudo apt-get -y install default-jdk",
    "curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch |sudo gpg --dearmor -o /usr/share/keyrings/elastic.gpg",
    "echo \"deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main\" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list",

    "sudo apt -y update && sudo apt -y install logstash",
    "sudo mv /home/ubuntu/logstash.conf /etc/logstash/conf.d/logstash.conf",
    "sudo sed -i 's/localhost:9200/${var.puppetmaster_ip}:9200/g' /etc/logstash/conf.d/logstash.conf",
    "sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t",
    "sudo systemctl start logstash",
    "sudo systemctl enable logstash",

    "sudo apt -y update && sudo apt -y install filebeat",
    "sudo sed -i \"s/output.elasticsearch:/#output.elasticsearch:/g\" /etc/filebeat/filebeat.yml",
    "sudo sed -i 's/hosts: \\[\"localhost:9200\"\\]/#hosts: \\[\"localhost:9200\"\\]/g' /etc/filebeat/filebeat.yml",
    "sudo sed -i \"s/#output.logstash:/output.logstash:/g\" /etc/filebeat/filebeat.yml",
    "sudo sed -i 's/#hosts: \\[\"localhost:5044\"\\]/hosts: \\[\"localhost:5044\"\\]/g' /etc/filebeat/filebeat.yml",
    "sudo filebeat modules enable system",
    "sudo filebeat setup --pipelines --modules system",
    "sudo filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=[\"localhost:9200\"]'",
    "sudo filebeat setup -E output.logstash.enabled=false -E output.elasticsearch.hosts=['localhost:9200'] -E setup.kibana.host=localhost:5601",
    "sudo systemctl start filebeat",
    "sudo systemctl enable filebeat",

    # "sudo apt -y update && sudo apt -y install metricbeat",
    # "sudo sed -i 's/output.elasticsearch:/#output.elasticsearch:/g' /etc/metricbeat/metricbeat.yml",
    # "sudo sed -i 's/hosts: [\"localhost:9200\"]/#hosts: [\"localhost:9200\"]/g' /etc/metricbeat/metricbeat.yml",
    # "sudo sed -i 's/#output.logstash:/output.logstash:/g' /etc/metricbeat/metricbeat.yml",
    # "sudo sed -i 's/#hosts: [\"localhost:5044\"]/hosts: [\"localhost:5044\"]/g' /etc/metricbeat/metricbeat.yml",
    # "sudo metricbeat modules enable system",
    # "sudo metricbeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=[\"localhost:9200\"]'",
    # "sudo metricbeat setup -E output.logstash.enabled=false -E output.elasticsearch.hosts=['localhost:9200'] -E setup.kibana.host=localhost:5601",
    # "sudo systemctl start metricbeat",
    # "sudo systemctl enable metricbeat",
    ]
  }
  
  block_device {
        uuid = "${data.openstack_images_image_v2.name.id}"
        source_type = "image"
        destination_type = "volume"
        volume_size = 10
        boot_index = 0
        delete_on_termination = true
    }
}