{ config, lib, machineName, pkgs, secrets, ... }:

let
  cfg = config.my.roles.seedbox;

  hostname = "seedbox.delroth.net";

  transmissionRpcPort = 9091;

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

      isolateServices = [ "transmission" "protonvpn-pmp-transmission" ];
      forwardPorts = [ transmissionRpcPort ];
    };

    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      group = "nas";

      settings = {
        download-dir = "${downloadBase}/default";
        incomplete-dir = "${downloadBase}/incomplete";

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

    # Transmission 3.0 leaks memory like crazy, restrict it to 2GB RAM and auto
    # restart.
    systemd.services.transmission.serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      MemoryMax = "2G";
    };

    systemd.services.protonvpn-pmp-transmission = {
      description = "ProtonVPN PMP Transmission notifier";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        ExecStart = "${pkgs.protonvpn-pmp-transmission}/bin/protonvpn-pmp-transmission --transmission_url http://delroth:${secrets.transmissionPassword}@127.0.0.1:${toString transmissionRpcPort} --pmp_gateway ${secrets.seedbox-vpn.gatewayIp4}";
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
  };
}
