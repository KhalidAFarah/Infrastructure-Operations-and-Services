class sensu-client::configure {
  File{
    require => Class['sensu-client::install'],
  }

  file { "/etc/sensu/ssl":
    owner => root,
    group => root,
    mode => 644,
    recurse => true,
    source => "puppet://modules/sensu-client/ssl",
  }

  file { "/etc/sensu/plugins":
    owner => root,
    group => root,
    mode => 755,
    recurse => true,
    source => "puppet://modules/sensu-client/plugins",
  }

  file { "/etc/sensu/config.json":
    owner => root,
    group => root,
    mode => 644,
    source => "puppet://modules/sensu-client/config.json",
    notify => Service['sensu-client'],
    require => File['/etc/sensu/ssl', '/etc/sensu/plugins'],
  }



  file { "/etc/sensu/conf.d/client.json":
    owner => root,
    group => root,
    mode => 644,
    recurse => true,
    source => "puppet://modules/sensu-client/plugins",
    require => File['/etc/sensu/config.json'],
    content => template("sensu-client/client.json.erb"),
    notify => Service['sensu-client'],
  }


}
