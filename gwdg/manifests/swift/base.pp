class gwdg::swift::base {

  Exec {
    logoutput => true,
  }

  $swift_local_net_ip   = $ipaddress_eth1
  $swift_verbose        = hiera('verbose', 'True')

  class { 'ssh::server::install': }

  class { 'swift':
    # shared salt used when hashing ring mappings
    swift_hash_suffix => hiera('swift_shared_secret'),
    package_ensure    => latest
  }


}
