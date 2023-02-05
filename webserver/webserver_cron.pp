cron { "PuppetManifest":
  hour => '*',
  minute => '*/2',
  ensure => present,
  command => "sudo puppet apply /home/ubuntu/webserver_manifest.pp",
}
