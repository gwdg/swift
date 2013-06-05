class gwdg::swift::storage(
	$zone 		= 1,
	$weight		= 100
) {
  
  include gwdg::swift::base

#  $device = "sdb"

  $swift_frontend_ip	= $gwdg::swift::base::swift_frontend_ip
  $swift_backend_ip	= $gwdg::swift::base::swift_backend_ip

  Swift::Storage::Server {
    replicator_concurrency => '8', 
    updater_concurrency    => '8',
    reaper_concurrency     => '8',
  }

  # Use 2 loopback devices for testing
#  swift::storage::loopback { ['1', '2']:
#     base_dir     => '/srv/loopback-device',
#     mnt_base_dir => '/srv/node',
#     require      => Class['swift'],
#  }

  class { 'swift::storage::all':
    storage_local_net_ip => $swift_backend_ip
  }
   
#  swift::storage::xfs { $device: #Reihenfolge zu swift::storage::all beachten? -> Anscheinend egal
#   require => Class['swift'];
#  }

  # 1. device

  @@ring_object_device 		{ "${swift_backend_ip}:6000/1":
    zone        => $zone,
    weight      => $weight,
  }

  @@ring_container_device 	{ "${swift_backend_ip}:6001/1":
    zone        => $zone,
    weight      => $weight,
  }

  @@ring_account_device 	{ "${swift_backend_ip}:6002/1":
    zone        => $zone,
    weight      => $weight,
  }

  # 2. device

  @@ring_object_device 		{ "${swift_backend_ip}:6000/2":
    zone        => $zone,
    weight      => $weight,
  }

  @@ring_container_device 	{ "${swift_backend_ip}:6001/2":
    zone        => $zone,
    weight      => $weight,
  }

  @@ring_account_device 	{ "${swift_backend_ip}:6002/2":
    zone        => $zone,
    weight      => $weight,
  }

  # collect resources for synchronizing the ring databases
  Swift::Ringsync<<||>>
}
