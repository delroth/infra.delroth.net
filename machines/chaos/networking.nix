{ lib, staging, ... }:

{
  config = lib.mkIf (!staging) {
    networking.dhcpcd.enable = false;
    networking.interfaces.ens3 = {
      ipv4.addresses = [
        { address = "195.201.9.37"; prefixLength = 26; }
        { address = "195.201.9.57"; prefixLength = 26; }
      ];
      ipv6.addresses = [
        { address = "2a01:4f8:13b:f15::1"; prefixLength = 64; }
        { address = "2a01:4f8:13b:f15::2"; prefixLength = 64; }
      ];
    };
    networking.defaultGateway = "195.201.9.58";
    networking.defaultGateway6 = {
      address = "fe80::1";
      interface = "ens3";
      sourceAddress = "2a01:4f8:13b:f15::1";
    };
    my.networking.externalInterface = "ens3";
  };
}
