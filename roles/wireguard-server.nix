{ config, lib, machineName, secrets, ... }:

let
  port = 51820;
  iface = "wg0";

  allPeers = secrets.wireguard.peers;
  thisPeer = allPeers."${machineName}";
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
        privateKey = secrets.wireguard.privateKeys."${machineName}";
        ips = [ "${thisPeer.vpnIp}/24" ];

        peers = map
          (peer: {
            allowedIPs = [ "${peer.vpnIp}/32" ];
            publicKey = peer.key;
          } // lib.optionalAttrs (peer ? externalIp) {
            endpoint = "${peer.externalIp}:${toString port}";
          })
          (lib.attrValues secrets.wireguard.peers);
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
