node 'www.foremanmaster.openstacklocal' {
  include ntp
#   exec { "sign_all":
#     path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
#     command => "sudo /opt/puppetlabs/bin/puppetserver ca sign --all",
#     unless => "sudo /opt/puppetlabs/bin/puppetserver ca list | grep \"No certificates to list\"",
#   }
}

node default {
  include ntp   
  if !($hostname =~ "backup-\d+") and !($hostname =~ "www.foremanmaster.openstacklocal"){
    group{ "webadmin":
      ensure => present,
    }
    user{ "tom":
      ensure => present,
      managehome => true,
      groups => ["sudo","webadmin"],
    }
    user{ "brady":
      ensure => present,
      managehome => true,
      groups => ["sudo","webadmin"],
    }
    user{ "janet":
      ensure => present,
      managehome => true,
      groups => ["sudo","webadmin"],
    }

    file { "/etc/sudoers.d/webadmin":
      ensure => present,
      owner => "root",
      group => "root",
      mode => "0440",
      content => "# sudo access without password for members of webadmin\n%webadmin ALL=(ALL) NOPASSWD: ALL",
      #unless => "sudo visudo -c | grep webadmin",
    }
  }

  if $hostname =~ "loadbalancer-\d+" {
    package{ 'pound':
      ensure => present,
    }
  }
  if $hostname =~ "databaseserver-\d+" {
    package { "mysql-server":
      ensure => present,
    }
  }
  if $hostname =~ "webserver-\d+" {
    package { "apache2":
      ensure => present,
    }
    class { "::php::globals":
      php_version => "5.6",
      config_root => "/etc/php/5.6",
    }
    class { "::php":
      manage_repos => true,
      ensure => present,
      require => Class["::php::globals"],
    }
    package { "php-mysql":
      ensure => present,
      require => Class['::php'],
    }
  }
}
