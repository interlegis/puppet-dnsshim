#slave.pp

class dnsshim::slave (	$ns_hidden_master,
			$ns_slaves,
			$directory = '/var/cache/bind',
			$ha_resource,
		        ){

  # Install package requirements
  $prereqs = [ "bind9"]
  define pkgpreq {
    if !defined(Package[$title]) {
      package { $title: ensure => present; }
    }
  }
  pkgpreq {$prereqs: }

  # Configure keys
  file {'/etc/bind/rndc.key': ensure => absent, }
  file {'/etc/bind/named.conf.local': ensure => absent, }

  file {'/etc/bind/rndc.conf':
    owner => 'bind', group => 'bind', mode => '0440',
    content => template('dnsshim/slaves/rndc.conf.erb'),
  }

  file {'/etc/bind/named.conf.options':
    owner => 'bind', group => 'bind', mode => '0440',
    content => template('dnsshim/slaves/named.conf.options.erb'),
  }

  file {'/etc/bind/named.conf':
    owner => 'bind', group => 'bind', mode => '0440',
    content => template('dnsshim/slaves/named.conf.erb'),
  }

  # Cria diretórios do dnsshim
  $libdir = '/usr/local/lib/dnsshim'
  file {$libdir:
    ensure => directory,
    owner => 'root', group => 'root', mode => '0550',
  }

  file {"${libdir}/CreateZoneDirs.sh":
    owner => 'root', group => 'root', mode => '0550',
    content => template('dnsshim/slaves/CreateZoneDirs.sh.erb'),
  }

  exec {'create dnsshim folders':
    command => "${libdir}/CreateZoneDirs.sh",
    creates => "$directory/dnsshim",
    cwd => "$directory",
    logoutput => false,
    timeout => 30,
    user => 'root',
    require => [
      File["${libdir}/CreateZoneDirs.sh"],
    ],
  }

  # HA BindReload resource
  if $ha_resource == true {
    file {'/etc/ha.d/resource.d/ReloadBind':
      owner => root, group => root, mode => '0550',
      content => template('dnsshim/slaves/ReloadBind.erb'),
      require => Package['heartbeat'],
    }
  }
}

