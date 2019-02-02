{ lib, staging, ... }:

{
  config = lib.mkIf (!staging) {
    networking.dhcpcd.enable = false;
    networking.interfaces.ens3 = {
      ipv4.addresses = [{
        address = "149.56.130.157";
        prefixLength = 32;
      }];
      ipv4.routes = [{
        address = "149.56.128.1";
        prefixLength = 32;
      }];
      ipv6.addresses = [{
        address = "2607:5300:201:3000::1b25";
        prefixLength = 64;
      }];
    };
    networking.defaultGateway = "149.56.128.1";
    networking.defaultGateway6 = "2607:5300:201:3000::1";
    my.networking.externalInterface = "ens3";
  };
}
