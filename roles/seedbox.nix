{ config, lib, machineName, secrets, ... }:

let
  cfg = config.my.roles.seedbox;

  hostname = "seedbox.delroth.net";

  transmissionRpcPort = 9091;
  transmissionExternalPort = 30251;

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

    # Use forked transmission version.
    nixpkgs.overlays = [(self: super: {
      transmission = super.transmission.overrideAttrs (old: {
        src = self.fetchFromGitHub {
          owner = "delroth";
          repo = "transmission";
          rev = "5681bd98fefbc58c64d18a98b10bf65e0b90810c";
          sha256 = "sha256-XQN+nZup2pGQgoKU1FT4Pdo6mHOHZMOYMFIXz73VOQY=";
          fetchSubmodules = true;
        };
      });
    })];

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

        verify-threads = 4;
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
