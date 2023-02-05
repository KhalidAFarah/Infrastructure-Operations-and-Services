# puppet apply --noop lecture.pp
# puppet apply --verbose lecture.pp
# puppet apply --test lecture.pp

user { "testuser":
  ensure => present,
}

ssh_authorized_key { "master_root":
  key => "and32Aksd...asdKa312nD1",
  user => root,
  ensure => present,
  type => rsa,
}

package { "emacs":
  ensure => present,
}

service { "munin-node":
  ensure => running,
  hasrestart => true,
}

exec { "create_myfile":
  path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
  command => "touch /tmp/myfile",
  unless => "ls /tmp/myfile", # onlyif, unless
  # unless condition {
  #   # when false
  # }
  # else {
  #   # when false
  # }
}

cron { "run_backup":
  command => "/usr/bin/backup.pl",
  user => root,
  minute => 0,
  hour => 5,
  ensure => present,
}

package { "mytool":
  ensure => present,
}
exec { "run_mytool":
  path => "....",
  command => "mytool ...."
  require => package['mytool']
# }

augeas { "sshd_config":
  context => "/files/etc/ssh/sshd_config",
  changes => [
    "set PermitRootLogin no",
  ],
}

exec { "create_myfile_notify":
  path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
  command => "touch /tmp/myfile",
  unless => "ls /tmp/myfile",
  notify => "File was created!"
}

case $operatingsystem {
  centos, redhat: { $apache = "httpd" }
  debian, ubuntu: { $apache = "apache2" }
  default: { fail("Unrecognized operating system for webserver") }
}

package { "apache":
  name => $apache,
  ensure => latest,
}

file { "motd":
  ensure => file,
  path => "/etc/motd",
  mode => 0644,
  content => "This VM is set up and managed by COMPANY NAME. This VM's IP address is ${ipaddress}. It thinks its hostname is ${fqdn}.
  
  It is running ${operatingsystem} ${operatingsystemrelease} and Puppet ${puppetversion}.",
}

