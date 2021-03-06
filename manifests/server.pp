# Class: openvpn::server
#
# Install and configure the OpenVPN server
#
class openvpn::server (
  $auth                     = 'SHA1',
  $ca                       = 'ca.crt',
  $cert                     = 'server.crt',
  $cipher                   = undef,
  $client_cert_not_required = '',
  $client_to_client         = false,
  $crl                      = undef,
  $dev                      = 'tun',
  $dev_type                 = '',
  $dh                       = 'dh2048.pem',
  $dh_size                  = 2048,
  $dns                      = '',
  $domain                   = '',
  $wins                     = '',
  $duplicate_cn             = '',
  $ifconfig                 = '',
  $key                      = 'server.key',
  $log                      = '',
  $log_append               = '',
  $status_log               = 'openvpn-status.log',
  $plugins                  = '',
  $verb                     = '3',
  $port                     = '1194',
  $proto                    = 'udp',
  $redirect_gateway         = '',
  $route                    = [],
  $route_ipv6               = [],
  $server                   = '10.8.0.0 255.255.255.0',
  $server_ipv6              = undef,
  $username_as_common_name  = '',
  $script_security          = '',
  $client_connect           = '',
  $client_disconnect        = '',
  $tls_auth                 = false,
  $tls_verify               = '',
  $topology                 = 'subnet',
  $custom_options           = [],
  $ccd                      = 'ccd',
  $purge_ccd                = false,
  $compress                 = 'legacy',
  $keepalive                = '10 120',
  $learn_address            = '',
) {

  include openvpn
  $openvpn_dir   = $openvpn::openvpn_dir
  $openvpn_group = $openvpn::openvpn_group
  $openvpn_user  = $openvpn::openvpn_user
  $openssl       = $openvpn::openssl

  if ( $log_append != '' ) and ( $log != '' ){
    err('Log_append and log should not both be defined')
  }

  $ccd_dir = $ccd ? {
      /^\/.*/ => $ccd,
      default => "${openvpn_dir}/${ccd}",
  }
  @file { $ccd_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 0,
    mode    => '0755',
    purge   => $purge_ccd,
    recurse => $purge_ccd,
  }

  # Server configuration file
  #file { "${openvpn_dir}/${name}.conf":
  file { "${openvpn_dir}/openvpn.conf":
    owner   => root,
    group   => 0,
    mode    => '0600',
    content => template('openvpn/server.conf.erb'),
  }

  $fq_dh = $dh ? {
      /^\/.*/ => $dh,
      default => "${openvpn_dir}/${dh}",
  }
  exec { "create ${dh}":
    cwd     => $openvpn_dir,
    command => "${openssl} dhparam -out ${fq_dh} ${dh_size}",
    creates => $fq_dh,
  }

  if $tls_auth {
    exec { 'create tls_auth key':
      cwd     => $openvpn_dir,
      command => 'openvpn --genkey --secret ta.key',
      creates => "${openvpn_dir}/ta.key",
    }
  }

  if $openvpn::manage_service {
    Exec["create ${dh}"] ~> Service['openvpn']

    File["${openvpn_dir}/openvpn.conf"] ~> Service['openvpn']
  }
}
