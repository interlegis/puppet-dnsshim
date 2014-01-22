# init.pp

class dnsshim ( $ns_hidden_master,
                $ns_slaves,
                $source = undef,
                $pydnsshimsrc = '',
		$installdir = '/opt',
		$dnsshim_home = '/etc/dnsshim',
		$db_host = 'localhost',
		$db_name = 'dnsshim',
		$db_user = 'dnsshim',
		$db_password = '',
		$db_port = 3306,
		$master_loglevel = 'INFO',
		$master_loglocation = '/var/log/dnsshim',
		$master_logdays = '60',
                $haresource = false,
		) {
  if $source {
     # Master install
     class { "dnsshim::master":
	ns_hidden_master => $ns_hidden_master,
        ns_slaves => $ns_slaves,
	source => $source,
	installdir => $installdir,
	dnsshim_home => $dnsshim_home,
        db_host => $db_host,
	db_name => $db_name,
	db_user => $db_user,
	db_password => $db_password,
	db_port => $db_port,
	log_level => $master_loglevel,
	log_location => $master_loglocation,
	log_age_days => $master_logdays,
     }
     if $pydnsshimsrc != '' {
        class { "dnsshim::pydnsshim":
	  installdir => $installdir,
	  source => $pydnsshimsrc,
	}
     } else {
	notify { "Pydnsshim warning":
	  message => "Pydnsshim not installed: command line utility will not be available." 
	}
     }
  } else {
     # Slave install
     class { "dnsshim::slave":
        ns_hidden_master => $ns_hidden_master,
        ns_slaves => $ns_slaves,
	ha_resource => $haresource,
     }
  }
}
