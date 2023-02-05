augeas { "PermitRootLogin":
  context => "/files/etc/ssh/sshd_config",
  changes => [
    "set PermitRootLogin without-password",
  ],
}

exec { "restart_ssh":
  path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
  user => "root",
  command => "service sshd restart",
}
