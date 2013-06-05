class gwdg::swift::base(
	$verbose       		= true,
	$shared_secret 		= undef,
	$packages      		= latest,
	$frontend_interface	= "eth0",
	$backend_interface	= "eth2"
){

  Exec {
    logoutput => true,
  }

  # Get IPs dynamically from interfaces

  $facter_frontend_interface	= "ipaddress_${frontend_interface}"
  $facter_backend_interface 	= "ipaddress_${backend_interface}"

  $swift_frontend_ip  		= inline_template('<%= scope.lookupvar(facter_frontend_interface) %>')
  $swift_backend_ip		= inline_template('<%= scope.lookupvar(facter_backend_interface) %>')

  class { 'ssh::server::install': }

  class { 'swift':
    # Shared salt used when hashing ring mappings
    swift_hash_suffix => $shared_secret, 
    package_ensure    => $packages
  }
}
