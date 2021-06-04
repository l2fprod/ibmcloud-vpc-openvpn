---
- hosts: bastion
  gather_facts: true
  roles:
    - {
      role: oefenweb.apt,
      apt_update: true,
      apt_upgrade: false,
      apt_install: [ "openvpn" ]
    }
    - {
      role: kyl191.openvpn,
      openvpn_port: 65000,
      # allow VPN from the machine running ansible
      clients: [ mymachine ],
      openvpn_fetch_config_dir: "./client-config",
      openvpn_push: [
%{ for subnetIndex, subnet in subnets ~}
        # route to subnet ${subnet.name}
        "route ${cidrhost(subnet.ipv4_cidr_block, 0)} ${cidrnetmask(subnet.ipv4_cidr_block)}",
%{ endfor ~}
%{ for routeIndex, route in routes ~}
        # additional route ${routeIndex}
        "route ${route}",
%{ endfor ~}
        # https://cloud.ibm.com/docs/vpc?topic=vpc-service-endpoints-for-vpc#cloud-service-endpoints
        "route 166.9.0.0 255.255.0.0",
        # https://cloud.ibm.com/docs/vpc?topic=vpc-service-endpoints-for-vpc#infrastructure-as-a-service-iaas-endpoints
        "route 161.26.0.0 255.255.0.0",
        # Private DNS
        "dhcp-option DNS 161.26.0.7",
        "dhcp-option DNS 161.26.0.8"
      ],
      openvpn_server_hostname: "${bastion_ip}",
      # avoid redirecting all traffic to the VPN
      openvpn_redirect_gateway: false,
      openvpn_server_network: "${openvpn_server_network}",
      openvpn_set_dns: false,
      # compression is considered insecure, disable it
      # https://community.openvpn.net/openvpn/wiki/VORACLE
      openvpn_compression:
    }
