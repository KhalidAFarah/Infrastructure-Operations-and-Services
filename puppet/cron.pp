cron { "PermitRootLogin":
  hour => '*',
  minute => '*/2',
  ensure => present,
  command => "sudo puppet apply /home/ubuntu/puppet/permitrootlogin.pp"
}
cron { "hping3":
  hour => '*',
  minute => '*/2',
  ensure => present,
  command => "sudo puppet apply /home/ubuntu/puppet/hping.pp"
}
