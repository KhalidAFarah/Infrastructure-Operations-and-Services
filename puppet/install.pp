class sensu-client::install {
  exec { "add_key":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    command => "wget -q http://repos.sensuapp.org/apt/pubkey.gpg -O - | sudo apt-key add -", 
    unless => "grep sensuapp /etc/apt/sources.list",
  }

  exec { "add_repo":
    path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
    command => "echo 'deb http://repos.sensuapp.org/apt sensu main' >> /etc/apt/souces.list;apt-get update",
    require => Exec['add_key'],
  }
  package { "redis-server":
    ensure => "installed",
    require => Exec['add_repo'],
  }
  package { "sensu":
    ensure => "installed",
    require => Exec['redis-server'],
  }
}
