{ config, pkgs, ... }:

let
  secondaryDnsServers = [
    "69.65.50.192"  # ns2.afraid.org
    "204.42.254.5"  # puck.nether.net
  ];
in {
  services.bind = {
    enable = true;
    extraOptions = ''
      notify yes;
    '';
    zones = [
      {
        master = true;
        name = "delroth.net";
        file = "/srv/dns/delroth.net.zone";
        slaves = secondaryDnsServers;
      }
      {
        master = true;
        name = "6.2.4.6.8.6.1.0.2.0.a.2.ip6.arpa";
        file = "/srv/dns/6.2.4.6.8.6.1.0.2.0.a.2.ip6.arpa.zone";
        slaves = secondaryDnsServers;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
