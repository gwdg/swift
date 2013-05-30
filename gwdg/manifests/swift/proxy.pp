class gwdg::swift::proxy {
  
  include gwdg::swift::base

  $swift_local_net_ip = $gwdg::swift::base::swift_local_net_ip

  # curl is only required for testing 
  package { 'curl':
    ensure => present
  }

  class { 'memcached':
#    listen_ip => $swift_local_net_ip,
    listen_ip => '127.0.0.1',
  }

  # Specify swift proxy and all of its middlewares
  class { 'swift::proxy':
    proxy_local_net_ip => $swift_local_net_ip,
    pipeline           => [
      'catch_errors',
      'healthcheck',
      'cache',
#      'ratelimit',
#      'swift3',
#      's3token',
#      'authtoken',
      'tempauth', # Anstatt keystone
      'proxy-server'
    ],
    # TODO where is the  ringbuilder class? -> inherit
    require            => Class['swift::ringbuilder'],
  }

  # configure all of the middlewares
  class {'swift::proxy::catch_errors': }
  class {'swift::proxy::healthcheck': }
  class {'swift::proxy::cache': }
#  class {'swift::proxy::swift3': }
  class {'swift::proxy::tempauth': }


  # collect all of the resources that are needed
  # to balance the ring
  Ring_object_device    <<| |>>
  Ring_container_device <<| |>>
  Ring_account_device   <<| |>>

  # create the ring
  class { 'swift::ringbuilder':
    # the part power should be determined by assuming 100 partitions per drive
    part_power     => '18',
    replicas       => '3',
    min_part_hours => 1,
    require        => Class['swift'],
  }

  # sets up an rsync db that can be used to sync the ring DB
  class { 'swift::ringserver':
    local_net_ip => $swift_local_net_ip,
  }

  # exports rsync gets that can be used to sync the ring files
  @@swift::ringsync { ['account', 'object', 'container']:
   ring_server => $swift_local_net_ip
  }
}
