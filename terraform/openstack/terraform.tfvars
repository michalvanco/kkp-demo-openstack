cluster_name          = "kkp-openstack-michal"
ssh_public_key_file   = "~/.ssh/id_rsa.pub"
ssh_username          = "root"
worker_os             = "ubuntu"
external_network_name = "e2e-tests"
control_plane_flavor  = "m1.small"
worker_flavor         = "m1.small"
lb_flavor             = "m1.tiny"
# More variables can be overridden here, see variables.tf
