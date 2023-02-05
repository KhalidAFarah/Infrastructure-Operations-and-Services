node 'puppetmaster.openstacklocal' {
  package{ 'hping3':
    ensure => "installed",
  }
}

node 'agent.openstacklocal'{
  package { 'hping3':
    ensure => "installed",
  }
  package { 'jed':
    ensure => "installed",
  }
}
