{ config, pkgs, ... }:

{
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
        slaves = [
          "69.65.50.192"  # ns2.afraid.org
          "204.42.254.5"   # puck.nether.net
        ];
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
