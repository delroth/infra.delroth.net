{ config, pkgs, ... }:

{
  networking.hostName = "chaos.delroth.net";
  networking.dhcpcd.enable = false;
  networking.interfaces.ens3.ipv4.addresses = [{
    address = "195.201.9.37";
    prefixLength = 26;
  }];
  networking.defaultGateway = "195.201.9.58";
  networking.nameservers = ["8.8.8.8" "4.4.4.4"];
  networking.firewall.allowPing = true;
}
