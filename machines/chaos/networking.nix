{ lib, staging, ... }:

{
  config = lib.mkIf (!staging) {
    networking.dhcpcd.enable = false;
    networking.interfaces.ens3.ipv4.addresses = [{
      address = "195.201.9.37";
      prefixLength = 26;
    }];
    networking.defaultGateway = "195.201.9.58";
  };
}
