{
  config,
  lib,
  machineName,
  secrets,
  ...
}:

let
  cfg = config.my.roles.wireguard-peer;
  port = 51820;
  iface = "wg";

  wgcfg = secrets.wireguard.cfg;
  allPeers = secrets.wireguard.peers;
  thisPeer = allPeers."${machineName}" or null;
  otherPeers = lib.filterAttrs (n: v: n != machineName) allPeers;
in
{
  options = {
    my.roles.wireguard-peer.enable = lib.mkEnableOption "Wireguard peer";
  };

  config = lib.mkIf cfg.enable {
    networking =
      let
      in
      {
        wireguard.interfaces."${iface}" = {
          listenPort = port;
          privateKey = secrets.wireguard.privateKeys."${machineName}";
          ips = [
            "${wgcfg.subnet4}.${toString thisPeer.clientNum}/${toString wgcfg.mask4}"
            # Technically, should hex-convert clientNum... but holes are fine.
            "${wgcfg.subnet6}::${toString thisPeer.clientNum}/${toString wgcfg.mask6}"
          ];

          peers =
            lib.mapAttrsToList
              (
                name: peer:
                {
                  inherit name;
                  allowedIPs = [
                    "${wgcfg.subnet4}.${toString peer.clientNum}/32"
                    "${wgcfg.subnet6}::${toString peer.clientNum}/128"
                  ];
                  publicKey = peer.key;
                }
                // lib.optionalAttrs (peer ? externalIp) { endpoint = "${peer.externalIp}:${toString port}"; }
                // lib.optionalAttrs (!(thisPeer ? externalIp)) { persistentKeepalive = 10; }
              )
              otherPeers;
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
