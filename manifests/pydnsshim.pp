# pydnsshim.pp

class dnsshim::pydnsshim ( $installdir = '/opt',
			   $source,
			) {

   define pkgpreq {
     if !defined(Package[$title]) {
       package { $title: ensure => present; }
     }
   }

   if $source {
     
     archive { 'pydnsshim':
        ensure           => present,
        url              => $source,
        target           => "$installdir",
        checksum         => false,
        strip_components => 1,
        notify           => Exec["install pydnsshim"],
     }

     # Install package requirements
     $prereqs = [ "python-cheetah" ]
     pkgpreq {$prereqs: }

     exec { 'install pydnsshim':
	command => "python $installdir/pydnsshim/setup.py install",
	timeout => 600,
	logoutput => true,
	refreshonly => true,
	require => Archive['pydnsshim'],
     }

   } else {
     fail ("Pydnsshim source not defined!")
   }
}
