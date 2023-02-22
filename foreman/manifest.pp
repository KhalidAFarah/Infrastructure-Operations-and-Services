node 'www.foremanmaster.openstacklocal' {
  include ntp
  exec { "sign_all":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    command => "sudo /opt/puppetlabs/bin/puppetserver ca sign --all",
    unless => "sudo /opt/puppetlabs/bin/puppetserver ca list | grep \"No certificates to list\"",
  }
}

node default {
  include ntp   
}

if $hostname =~ "foreman-agent-\d+" {
  include docker
  package { 'jed':
    ensure => present,
  }
}
