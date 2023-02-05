wget 
sudo dpkg -i ./puppet7-release-focal.deb
sudo apt update
sudo install -y puppetserver

#under the /etc/hosts
212.162.147.82 puppet.master.openstacklocal puppetmaster

 #under the /etc/puppetlabs/puppet/puppet.conf
dns_alt_names=puppetmaster.openstacklocal.puppetmaster

[main]
certname = puppetmaster.openstacklocal
server = puppetmaster.openstacklocal
envirronment = production
runinterval = 30m


#vefore starting the puppetserver set up certificates by:
sudo /opt/puppetlabs/bin/puppetserver ca setup
sudo systemctl start puppetserver

#installing
sudo apt-get install puppet-agent -y
#connect to master
sudo /opt/puppetlabs/bin/puppet agent --test
#you might need to specify explicitly for the agent who the puppet master is:
sudo /opt/puppetlabs/bin/puppet config set server puppetmaster
#
sudo /opt/puppetlabs/bin/puppetserver ca sign --all

#have the puppet manifest "manifests.pp" under /etc/puppetlabs/code/envirronments/production/manifests 

#under the /etc/puppetlabs/puppet/puppet.conf for the puppet agents
[main]
certname = slave.openstacklocal
server = puppetmaster.openstacklocal

#then do
sudo systemctl start puppet
sudo /opt/puppetlabs/bin/puppet agent --test 
