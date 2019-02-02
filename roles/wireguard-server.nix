{ config, lib, machineName, ... }:

let
  my = import ../.;
in {
  networking.wireguard.interfaces.wg0 = {
    listenPort = 51820;
    privateKey = my.secrets.wireguard.privateKeys."${machineName}";
    ips = [ "10.13.37.254/24" ];

    peers = map
      (key: {
        allowedIPs = [ "10.13.37.0/24" ];
        publicKey = key;
      })
      (lib.attrValues my.secrets.wireguard.publicKeys);
  };
}
