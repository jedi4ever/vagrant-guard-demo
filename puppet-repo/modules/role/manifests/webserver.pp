class role::webserver {
  include apache
  package { 'lynx':
    ensure => present
  }

  package { 'lynxbla':
    ensure => present
  }

   apache::vhost { 'localhost':
     priority => '20',
     port     => '80',
     docroot  => '/var/www/',
   }

}
