{ config, machineName, ... }:

let
  my = import ../.;
in {
  networking.wireguard.interfaces.wg0 = {
    listenPort = 51820;
    privateKey = my.secrets.wireguard.privateKeys."${machineName}";
    ips = [ "10.13.37.1/24" ];
  };
}
