{ config, lib, machineName, ... }:

let
  my = import ../.;
  port = 51820;
  iface = "wg0";
in {
  options.my.networking.externalInterface = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = ''
      Name of the network interface that egresses to the internet. Used for
      e.g. NATing internal networks.
    '';
  };

  config = {
    networking = {
      wireguard.interfaces."${iface}" = {
        listenPort = port;
        privateKey = my.secrets.wireguard.privateKeys."${machineName}";
        ips = [ "10.13.37.254/24" ];

        peers = map
          (client: {
            allowedIPs = [ "${client.ip}/32" ];
            publicKey = client.key;
          })
          (lib.attrValues my.secrets.wireguard.clients);
      };

      nat = {
        enable = true;
        externalInterface = config.my.networking.externalInterface;
        internalInterfaces = [ iface ];
      };

      firewall.allowedUDPPorts = [ port ];
    };
  };
}
