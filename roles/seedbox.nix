{ config, lib, machineName, secrets, ... }:

let
  cfg = config.my.roles.seedbox;

  hostname = "seedbox.delroth.net";

  transmissionRpcPort = 9091;
  transmissionExternalPort = secrets.seedbox-vpn.publicPort;

  downloadBase = "/data/seedbox";
in {
  options.my.roles.seedbox = with lib; {
    enable = mkEnableOption "Seedbox";
  };

  config = lib.mkIf cfg.enable {
    my.services.wg-netns = {
      enable = true;

      privateKey = secrets.seedbox-vpn.privateKey;
      peerPublicKey = secrets.seedbox-vpn.publicKey;
      endpointAddr = secrets.seedbox-vpn.endpointAddr;
      ip4 = secrets.seedbox-vpn.ip4;
      ip6 = secrets.seedbox-vpn.ip6;

      isolateServices = [ "transmission" ];
      forwardPorts = [ transmissionRpcPort ];
    };

    services.transmission = {
      enable = true;
      group = "nas";

      settings = {
        download-dir = "${downloadBase}/default";
        incomplete-dir = "${downloadBase}/incomplete";

        peer-port = transmissionExternalPort;

        rpc-enabled = true;
        rpc-port = transmissionRpcPort;
        rpc-authentication-required = true;

        rpc-username = "delroth";
        rpc-password = secrets.transmissionPassword;

        # Proxied behind nginx.
        rpc-whitelist-enabled = true;
        rpc-whitelist = "127.0.0.1";
      };
    };

    services.flexget = {
      enable = true;
      user = "transmission";
      homeDir = "/var/lib/transmission";
      systemScheduler = false;
      config = secrets.flexget-config { inherit config; };
    };

    services.minidlna = {
      enable = true;
      mediaDirs = [
        "${downloadBase}/watchqueue"
      ];
      announceInterval = 10;
    };

    users.users.minidlna.extraGroups = [ "nas" ];

    my.backup.extraExclude = [ downloadBase ];

    services.nginx.virtualHosts."${hostname}" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString transmissionRpcPort}";
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ transmissionExternalPort ];
      allowedUDPPorts = [ transmissionExternalPort ];
    };
  };
}
