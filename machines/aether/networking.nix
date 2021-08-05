{ pkgs, ... }:

let
  iface = {
    # Default route. Get public v4/32 + v6/48 from there and route/NAT.
    # Current: top port on MLX CX4 PCIe NIC.
    upstream = "enP4p1s0f0np0";

    # Serves a simple DHCP for debug access if things are broken.
    # Current: Honeycomb 1G copper port.
    mgmt = "eth0";

    # List of downstreams to bridge.
    # Current: 4x Honeycomb 10G SFP+ + bottom port on MLX CX4 PCIe NIC.
    downstreams = [ "eth1" "eth2" "eth3" "eth4" "enP4p1s0f1np1" ];

    # Name of the downstream bridge.
    bridge = "downstream";
  };

  # v4 internal IP ranges. v6 uses prefix delegation from upstream
  range = {
    mgmt = {
      ip = "192.168.200.254";
      net = "192.168.200.0";
      mask = "255.255.255.0";
      cidr = 24;

      dhcpStart = "192.168.200.100";
      dhcpEnd = "192.168.200.200";
    };

    downstream = {
      ip = "192.168.1.254";
      net = "192.168.1.0";
      mask = "255.255.255.0";
      cidr = 24;

      dhcpStart = "192.168.1.100";
      dhcpEnd = "192.168.1.200";
    };
  };
in {
  networking.interfaces."${iface.upstream}" = {
    useDHCP = true;
  };

  networking.bridges."${iface.bridge}".interfaces = iface.downstreams;

  networking.interfaces."${iface.bridge}" = {
    ipv4.addresses = [
      {
        address = range.downstream.ip;
        prefixLength = range.downstream.cidr;
      }
    ];
  };

  networking.interfaces."${iface.mgmt}" = {
    ipv4.addresses = [
      {
        address = range.mgmt.ip;
        prefixLength = range.mgmt.cidr;
      }
    ];
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
  };

  services.dhcpd4 = {
    enable = true;
    interfaces = [ iface.bridge iface.mgmt ];
    configFile = pkgs.writeText "dhcpd4.conf" ''
      authoritative;
      default-lease-time 3600;
      max-lease-time 86400;
      log-facility local1;

      option domain-name "delroth.net";
      option domain-name-servers 8.8.8.8, 8.8.4.4;

      subnet ${range.downstream.net} netmask ${range.downstream.mask} {
        option routers ${range.downstream.ip};
        range ${range.downstream.dhcpStart} ${range.downstream.dhcpEnd};
      }

      subnet ${range.mgmt.net} netmask ${range.mgmt.mask} {
        option routers ${range.mgmt.ip};
        range ${range.mgmt.dhcpStart} ${range.mgmt.dhcpEnd};
      }
    '';
  };
}
