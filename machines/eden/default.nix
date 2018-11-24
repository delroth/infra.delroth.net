{ lib, machineName, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.common.serverBase

    my.roles.syncthingRelay
    my.roles.torRelay
  ];

  services.httpd.enable = true;
  services.httpd.adminAddr = "test@delroth.net";
  networking.firewall.allowedTCPPorts = [ 80 ];
}
