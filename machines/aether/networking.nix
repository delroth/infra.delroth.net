{ lib, pkgs, ... }:

let
  # v4 internal IP ranges. v6 uses prefix delegation from upstream
  range = {
    mgmt = {
      ip = "192.168.200.254";
      net = "192.168.200.";
      mask = "255.255.255.0";
      cidr = 24;

      dhcpStart = "192.168.200.100";
      dhcpEnd = "192.168.200.200";
    };

    downstream = {
      ip = "192.168.1.254";
      net = "192.168.1.";
      mask = "255.255.255.0";
      cidr = 24;

      dhcpStart = "192.168.1.100";
      dhcpEnd = "192.168.1.200";
    };
  };

  # Machines on the LAN.
  hosts = {
    velvet = { mac = "00:02:c9:23:bd:90"; ip = 1; };
    sw-living-room = { mac = "24:5e:be:53:fc:78"; ip = 50; };
  };

  dhcpHosts =
    let
      lines = lib.mapAttrsToList (hostname: info:
        "dhcp-host=${info.mac},${range.downstream.net}${toString info.ip},[::${toString info.ip}],${hostname}"
      ) hosts;
    in builtins.concatStringsSep "\n" lines;
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

  networking.dhcpcd.extraConfig = ''
    interface upstream
      persistent
      noipv4ll
      nodelay
      ia_na 1
      ia_pd 2 downstream/0
  '';

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

  networking.nat = {
    enable = true;
    externalInterface = "upstream";
    internalInterfaces = [ "downstream" ];
  };

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    extraConfig = ''
      port=0  # Disable DNS

      interface=downstream
      interface=mgmt
      bind-interfaces

      dhcp-authoritative
      dhcp-range=${range.mgmt.dhcpStart},${range.mgmt.dhcpEnd},15m
      dhcp-range=set:downstream,${range.downstream.dhcpStart},${range.downstream.dhcpEnd},15m
      dhcp-range=set:downstream,::ff00,::ffff,constructor:downstream,slaac,15m

      dhcp-option=tag:downstream,option:router,${range.downstream.ip}

      dhcp-option=option:dns-server,8.8.8.8,8.8.4.4
      dhcp-option=option6:dns-server,2001:4860:4860::8888,2001:4860:4860::8844

      ${dhcpHosts}

      enable-ra
    '';
  };

  networking.firewall.allowedUDPPorts = [ 67 547 ];
}
