{ pkgs, ... }:

let
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
  # Rename interfaces to logical semantic names.
  systemd.network.links = {
    "10-upstream" = {
      matchConfig.MACAddress = "50:6b:4b:38:93:ea";
      linkConfig.Name = "upstream";
    };
    "10-mgmt" = {
      matchConfig.MACAddress = "ee:31:06:c8:00:11";
      linkConfig.Name = "mgmt";
    };
    "10-down-25g" = {
      matchConfig.MACAddress = "50:6b:4b:38:93:eb";
      linkConfig.Name = "down-25g";
    };
    "10-down-10g-tl" = {
      matchConfig.MACAddress = "ee:31:06:c8:00:09";
      linkConfig.Name = "down-10g-tl";
    };
    "10-down-10g-tr" = {
      matchConfig.MACAddress = "ee:31:06:c8:00:07";
      linkConfig.Name = "down-10g-tr";
    };
    "10-down-10g-bl" = {
      matchConfig.MACAddress = "ee:31:06:c8:00:0a";
      linkConfig.Name = "down-10g-bl";
    };
    "10-down-10g-br" = {
      matchConfig.MACAddress = "ee:31:06:c8:00:08";
      linkConfig.Name = "down-10g-br";
    };
  };

  networking.interfaces.upstream = {
    useDHCP = true;
  };

  networking.bridges.downstream.interfaces = [
    "down-25g"
    "down-10g-tl"
    "down-10g-tr"
    "down-10g-bl"
    "down-10g-br"
  ];

  networking.interfaces.downstream = {
    ipv4.addresses = [
      {
        address = range.downstream.ip;
        prefixLength = range.downstream.cidr;
      }
    ];
  };

  networking.interfaces.mgmt = {
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
    interfaces = [ "downstream" "mgmt" ];
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
