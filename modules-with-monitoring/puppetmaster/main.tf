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


data "openstack_images_image_v2" "image" {
  name = var.image_name
  
}

data "openstack_compute_keypair_v2" "laptop" {
  name = "KF-Laptop-key"
}

# resource "openstack_blockstorage_volume_v3" "volume" {
#   name = "${var.name}_volume"
#   size = 10
#   region = "nova"
#   image_id = data.openstack_images_image_v2.image.id
# }


resource "openstack_compute_instance_v2" "foreman_puppetmaster" {
  provider = openstack
  name        = var.name
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = var.key_pair_name
  network {
    name = var.network_name
  }
  security_groups = var.security_groups

  block_device {
    uuid =  data.openstack_images_image_v2.image.id#openstack_blockstorage_volume_v3.volume.id
    source_type = "image"
    destination_type = "volume"
    boot_index = 0
    delete_on_termination = true
    volume_size = 10
  }

  connection {
    type        = "ssh"
    user        = var.user
    private_key = var.private_key
    host        = openstack_compute_instance_v2.foreman_puppetmaster.access_ip_v4
  }

  provisioner "file" {
    source      = var.manifest_file
    destination = "./manifest.pp"
  }
  provisioner "file" {
    source      = "./logstash.conf"
    destination = "./logstash.conf"
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "sleep 20",
  #     "sudo apt update -y",
  #     "sudo hostnamectl set-hostname www.${replace(self.name, "_", "")}.openstacklocal",
  #     "sudo bash -c 'echo \"${openstack_compute_instance_v2.foreman_puppetmaster.access_ip_v4} www.${replace(self.name, "_", "")}.openstacklocal\" >> /etc/hosts'",
  #     "sudo apt install -y apt-transport-https wget gpg gnupg ca-certificates",
  #     "curl -LO https://apt.puppet.com/puppet6-release-focal.deb",
  #     "sudo dpkg -i ./puppet6-release-focal.deb",
  #     "sudo apt update -y",
  #     "echo \"deb http://deb.theforeman.org/ focal 3.0\" | sudo tee /etc/apt/sources.list.d/foreman.list",
  #     "echo \"deb http://deb.theforeman.org/ plugins 3.0\" | sudo tee -a /etc/apt/sources.list.d/foreman.list",
  #     "wget -q http://deb.theforeman.org/pubkey.gpg -O- | sudo apt-key add -",
  #     "sudo apt-get update && sudo apt-get -y install foreman-installer",
  #     "sudo foreman-installer --foreman-initial-admin-username='${var.initial_admin_username}' --foreman-initial-admin-password='${var.initial_admin_password}'"
  #   ]
  # }
  # provisioner "remote-exec" {
  #    inline = var.puppet_modules
  #    #when = var.puppet_modules != []
  # }
  provisioner "remote-exec" {
    inline = ["sleep 20",
      "sudo mv ~/manifest.pp /etc/puppetlabs/code/environments/production/manifests/manifest.pp",
      "sudo /opt/puppetlabs/puppet/bin/puppet agent",
      "echo \"${data.openstack_compute_keypair_v2.laptop.public_key}\" >> ~/.ssh/authorized_keys",

      "sudo apt-get -y update && sudo apt-get -y install default-jre",
      "sudo apt-get -y update && sudo apt-get -y install default-jdk",
      #"sudo apt-get -y update && sudo apt-get -y install nginx",
      "curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main\" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list",
      "sudo apt -y update && sudo apt -y install elasticsearch",
      "sudo sed -i 's/#node.name:/node.name:/g' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i 's/#network.host: 192.168.0.1/network.host: ${openstack_compute_instance_v2.foreman_puppetmaster.access_ip_v4}/g' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i 's/#discovery.seed_hosts: \\[\"host1\", \"host2\"\\]/discovery.seed_hosts: \\[\"host1\"\\]/g' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i 's/#cluster.initial_master_nodes: \\[\"node-1\", \"node-2\"\\]/cluster.initial_master_nodes: \\[\"node-1\"]/g' /etc/elasticsearch/elasticsearch.yml",
      "sudo systemctl start elasticsearch",
      "sudo systemctl enable elasticsearch",
      "sudo apt -y update && sudo apt -y install kibana",
      "sudo sed -i 's/#server.host: \"localhost\"/server.host: ${openstack_compute_instance_v2.foreman_puppetmaster.access_ip_v4}/g' /etc/kibana/kibana.yml",
      "sudo sed -i 's|#elasticsearch.hosts: \\[\"http://localhost:9200\"\\]|elasticsearch.hosts: \\[\"http://${openstack_compute_instance_v2.foreman_puppetmaster.access_ip_v4}:9200\"\\]|g' /etc/kibana/kibana.yml",
      "sudo systemctl enable kibana",
      "sudo systemctl start kibana",
      #"echo \"kibanaadmin:`echo \"asd\" | openssl passwd -apr1 -stdin`\" | sudo tee -a /etc/nginx/htpasswd.users",

# server {
#     listen 80;
#     server_name your_domain;
#     auth_basic "Restricted Access";
#     auth_basic_user_file /etc/nginx/htpasswd.users;
#     location / {
#         proxy_pass http://localhost:5601;
#         proxy_http_version 1.1;
#         proxy_set_header Upgrade $http_upgrade;
#         proxy_set_header Connection 'upgrade';
#         proxy_set_header Host $host;
#         proxy_cache_bypass $http_upgrade;
#     }
# }

      #sudo ln -s /etc/nginx/sites-available/your_domain /etc/nginx/sites-enabled/your_domain
      #sudo nginx -t
      #sudo systemctl reload nginx
      #sudo ufw allow 'Nginx Full'

    "sudo apt -y update && sudo apt -y install logstash",
    "sudo mv /home/ubuntu/logstash.conf /etc/logstash/conf.d/logstash.conf",
    "sudo sed -i 's/localhost:9200/${openstack_compute_instance_v2.foreman_puppetmaster.access_ip_v4}:9200/g' /etc/logstash/conf.d/logstash.conf",
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
    "sudo filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=[\"${openstack_compute_instance_v2.foreman_puppetmaster.access_ip_v4}:9200\"]'",
    "sudo filebeat setup -E output.logstash.enabled=false -E output.elasticsearch.hosts=['${openstack_compute_instance_v2.foreman_puppetmaster.access_ip_v4}:9200'] -E setup.kibana.host=${openstack_compute_instance_v2.foreman_puppetmaster.access_ip_v4}:5601",
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
      # "sudo apt-get -y install apt-transport-https",
      # "wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -",
      # "echo \"deb https://artifacts.elastic.co/packages/7.x/apt stable main\" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list",
      # "sudo apt-get -y update && sudo apt-get -y install elasticsearch",
      # "sudo apt-get -y update && sudo apt-get -y install kibana",
      # "sudo apt-get -y update && sudo apt-get -y install logstash",
      # "sudo apt-get -y update && sudo apt-get -y install metricbeat",
      # "sudo apt-get -y update && sudo apt-get -y install packetbeat",

      # "sudo bash -c 'echo \"xpack.security.enabled: true\" >> /etc/elasticsearch/elasticsearch.yml'",
      # "sudo systemctl start elasticsearch kibana logstash",
      #"sudo bash -c 'echo \"xpack.security.authc.api_key.enabled: true\" >> /etc/elasticsearch/elasticsearch.yml'",

      # "sudo bash -c 'echo \"elasticsearch.username: XXXXX\" >> /etc/kibana/kibana.yml'",
      # "sudo bash -c 'echo \"elasticsearch.password: XXXXX\" >> /etc/kibana/kibana.yml'",


      #"sudo systemctl enable metricbeat packetbeat",
      #cat /etc/logstash/conf.d/input.conf
      #curl -X PUT -u username:oldpassword -H 'Content-Type: application/json' http://localhost:9200/_security/user/username/_password -d '{ "password": "newpassword" }'
      #sudo metricbeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.username=elastic' -E 'output.elasticsearch.password=KDpI9oo3GhNhDTBPrzWp' -E 'output.elasticsearch.hosts=["localhost:9200"]' -E 'output.elasticsearch.hosts=["localhost:9200"]' -E 'setup.kibana.host=localhost:5601'
      #sudo metricbeat setup -E output.logstash.enabled=false -E 'output.elasticsearch.username=elastic' -E 'output.elasticsearch.password=KDpI9oo3GhNhDTBPrzWp' -E 'output.elasticsearch.hosts=["localhost:9200"]' -E 'output.elasticsearch.hosts=["localhost:9200"]' -E 'setup.kibana.host=localhost:5601'
      ]
  }
}
#/etc/elasticsearch/jvm.options.d/test.options (added test.options)
#-Xms768m
#-Xmx768m

#/etc/logstash/jvm.options
#-Xms512m
#-Xmx512m