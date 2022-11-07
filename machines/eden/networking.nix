{ lib, ... }:

{
  networking.useDHCP = false;
  networking.interfaces.enp0s3 = {
    ipv4.addresses = [{
      address = "172.105.199.155";
      prefixLength = 24;
    }];
    ipv6.addresses = [{
      address = "2400:8902::f03c:91ff:feaf:723b";
      prefixLength = 64;
    }];

    ipv4.routes = [
      {
        address = "0.0.0.0";
        prefixLength = 0;
        via = "172.105.199.1";
        options.onlink = true;
      }
    ];
    ipv6.routes = [
      {
        address = "::";
        prefixLength = 0;
        via = "fe80::1";
        options.onlink = true;
      }
    ];
  };

  networking.tempAddresses = "disabled";  # Linode... why.
  my.networking.externalInterface = "enp0s3";
}
