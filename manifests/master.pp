#master.pp
class dnsshim::master (	$ns_hidden_master,
			$ns_slaves,
			$source,
			$installdir,
			$dnsshim_home,
		        $db_host,
		        $db_name,
        		$db_user,
		        $db_password,
		        $db_port,
			$log_level,
			$log_location,
			$log_age_days,
			){

  if ( $db_password == '' ) {
    fail ( "db_password must not be blank!" )
  }

  archive { 'dnsshim':
    ensure           => present,
    url              => $source,
    target           => "$installdir",
    checksum         => false,
    follow_redirects => true,
    strip_components => 1,
  }

  # Install package requirements
  $prereqs = [ "openjdk-6-jre-headless", "bind9utils"]
  define pkgpreq {
    if !defined(Package[$title]) {
      package { $title: ensure => present; }
    }
  }
  pkgpreq {$prereqs: }

  file { "$dnsshim_home":
    ensure => directory,
    owner => 'root', group => 'root',
  }

  file { "/etc/init.d/dnsshim":
    owner => root, group => root, mode => 555,
    content => template("dnsshim/master/dnsshim_init.erb"),
    require => [
      Package['openjdk-6-jre-headless'],
      Archive['dnsshim'],
    ],
  }

  service { "dnsshim":
    enable => true,
    ensure => 'running',
    require => [ File['/etc/init.d/dnsshim'],
                 File["$dnsshim_home/xfrd/conf/xfrd.properties"],
    ],
  }

  file { "$installdir/dnsshim/SlaveSync.sh":
    mode => 555,
    require => Archive["dnsshim"], 
  }
  
  file { "$dnsshim_home/xfrd/conf/xfrd.properties":
    owner => root, group => root, mode => 440,
    require => Archive["dnsshim"],
    content => template('dnsshim/master/xfrd.properties.erb'),
  }

  ## Log Configuration  
  file { "$log_location":
    owner => root, group => root, mode => 660,
    ensure => directory,
  } 

  file { "$installdir/dnsshim/log4j-xfrd.properties":
    owner => root, group => root, mode => 440,
    content => template('dnsshim/master/log4j-xfrd.properties.erb'),
    require => [ File["$log_location"],
		 Archive["dnsshim"],
    ],
    notify => Service['dnsshim'],
  }
	
  file { "$installdir/dnsshim/log4j-signer.properties":
    owner => root, group => root, mode => 440,
    content => template('dnsshim/master/log4j-signer.properties.erb'),
    require => [ File["$log_location"],
                 Archive["dnsshim"],
    ],
    notify => Service['dnsshim'],
  }
 
  ## Just erase log files 
  logrotate::rule { 'dnsshim':
    path => "$log_location/*.log.*",
    rotate => 0,
    rotate_every => 'day',
    missingok => true,
    create => false,
    maxage => $log_age_days,
  }

  ## RNDC Configuration
  file { "/etc/bind":
    owner => root, group => root, mode => 440,
    ensure => directory,
    require => Pkgpreq["bind9utils"],
  } 

  file { "/etc/bind/rndc.conf":
    owner => root, group => root, mode => 440,
    content => template('dnsshim/master/rndc.conf.erb'),
    require => File["/etc/bind"],
  }

}

