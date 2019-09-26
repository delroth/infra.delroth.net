{ config, lib, pkgs, secrets, ... }:

let
  secondaryDnsServers = [
    "69.65.50.192"  # ns2.afraid.org
    "204.42.254.5"  # puck.nether.net
  ];
in {
  # Move stubby to a separate port since we run Bind in front of it.
  services.stubby.listenAddresses = [
    "127.0.0.1@8053"
    "0::1@8053"
  ];

  services.bind = {
    enable = true;
    cacheNetworks = [
      "127.0.0.0/24"
      "::1/128"
    ];
    forwarders = ["127.0.0.1 port 8053"];
    extraOptions = ''
      notify yes;
    '';
    zones = [
      {
        master = true;
        name = "delroth.net";
        file = "/srv/dns/delroth.net.zone";
        slaves = secondaryDnsServers;
        extraConfig = ''
          key-directory "/etc/bind/keys";
          auto-dnssec maintain;
          inline-signing yes;
        '';
      }
      {
        master = true;
        name = "6.2.4.6.8.6.1.0.2.0.a.2.ip6.arpa";
        file = "/srv/dns/6.2.4.6.8.6.1.0.2.0.a.2.ip6.arpa.zone";
        slaves = secondaryDnsServers;
      }
    ];
  };

  environment.etc = lib.mapAttrs' (filename: contents: {
    name = "bind/keys/${filename}";
    value = {
      user = "named";
      group = "root";
      mode = "0400";
      text = contents;
    };
  }) secrets.dnssec;

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
