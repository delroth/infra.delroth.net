{ config, lib, machineName, secrets, ... }:

let
  cfg = config.my.roles.wireguard-peer;
  port = 51820;
  iface = "wg";

  allPeers = secrets.wireguard.peers;
  thisPeer = allPeers."${machineName}";
in {
  options = {
    my.networking.externalInterface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Name of the network interface that egresses to the internet. Used for
        e.g. NATing internal networks.
      '';
    };

    my.roles.wireguard-peer.enable = lib.mkEnableOption "Wireguard peer";
  };

  config = lib.mkIf cfg.enable {
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

      nat = lib.optionalAttrs (thisPeer ? externalIp) {
        enable = true;
        externalInterface = config.my.networking.externalInterface;
        internalInterfaces = [ iface ];
      };

      firewall.allowedUDPPorts = lib.optional (thisPeer ? externalIp) port;
    };
  };
}
