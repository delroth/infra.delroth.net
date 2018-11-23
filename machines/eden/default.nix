{ lib, machineName, ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.common.serverBase
  ];
  networking.hostName = "${machineName}.delroth.net";

  services.httpd.enable = true;
  services.httpd.adminAddr = "test@delroth.net";
  networking.firewall.allowedTCPPorts = [ 80 ];
}
