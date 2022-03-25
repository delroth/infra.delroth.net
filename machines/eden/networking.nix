{ lib, ... }:

{
  networking.dhcpcd.enable = false;
  networking.interfaces.enp0s3 = {
    ipv4.addresses = [{
      address = "172.105.199.155";
      prefixLength = 24;
    }];
    ipv6.addresses = [{
      address = "2400:8902::f03c:91ff:feaf:723b";
      prefixLength = 64;
    }];
  };
  networking.defaultGateway = "172.105.199.1";
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "enp0s3";
  };
  networking.tempAddresses = "disabled";  # Linode... why.
  my.networking.externalInterface = "enp0s3";
}
