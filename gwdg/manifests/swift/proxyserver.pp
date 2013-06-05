class gwdg::swift::proxyserver(
	$workers  = 8,
	$pipeline = []
){
  
  include gwdg::swift::base

  $swift_frontend_ip	= $gwdg::swift::base::swift_frontend_ip
  $swift_backend_ip	= $gwdg::swift::base::swift_backend_ip

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
    workers            => $workers,
    proxy_local_net_ip => $swift_frontend_ip,
    pipeline           => $pipeline,
    account_autocreate => true,
    # TODO where is the  ringbuilder class? -> inherit
    require            => Class['swift::ringbuilder'],
  }

  # configure all of the middlewares
  class {'swift::proxy::catch_errors': }
  class {'swift::proxy::healthcheck': }
  class {'swift::proxy::cache': }
#  class {'swift::proxy::swift3': }
  class {'swift::proxy::tempauth': }

#  class { 'swift::proxy::ratelimit':
#    clock_accuracy         => 1000,
#    max_sleep_time_seconds => 60,
#    log_sleep_time_seconds => 0,
#    rate_buffer_seconds    => 5,
#    account_ratelimit      => 0
#  }

#  class { 'swift::proxy::s3token':
#    # assume that the controller host is the swift api server
#    auth_host     => $swift_keystone_node,
#    auth_port     => '35357',
#  }

#  class { 'swift::proxy::keystone':
#    operator_roles => ['admin', 'SwiftOperator'],
#  }

#  class { 'swift::proxy::authtoken':
#    admin_user        => 'swift',
#    admin_tenant_name => 'services',
#    admin_password    => $swift_admin_password,
#    # assume that the controller host is the swift api server
#    auth_host         => $swift_keystone_node,
#  }

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
    local_net_ip => $swift_backend_ip,
  }

  # exports rsync gets that can be used to sync the ring files
  @@swift::ringsync { ['account', 'object', 'container']:
    ring_server => $swift_backend_ip
  }

  # deploy a script that can be used for testing
#  class { 'swift::test_file':
#    auth_server => $swift_keystone_node,
#    password    => $swift_keystone_admin_password,
#  }

}
