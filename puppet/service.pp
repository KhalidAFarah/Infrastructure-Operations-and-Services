class sensu-client::service {
  Service{
    require => Class['sensu-client::configure']
  }

  service { "sensu-client":
    ensure => "running",
    enable => "true",
    hasrestart => "true",
  }
}
