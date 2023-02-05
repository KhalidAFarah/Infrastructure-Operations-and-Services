package { "apache":
  name =>  "apache2",
  ensure => present,
}

exec { "add html":
  path => "/usr/bin/:/usr/sbin/:/usr/local/bin:/bin/:/sbin",
  user => "root",
  command => "mv /home/ubuntu/index.html /var/www/html/index.html",
  onlyif => "ls /home/ubuntu/index.html",
}
