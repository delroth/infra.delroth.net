{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.syncthing.relay;

  dataDirectory = "/var/lib/syncthing-relay";

  relayOptions = [
    "--keys=${dataDirectory}"
    "--listen=${cfg.listenAddress}:${toString cfg.port}"
    "--status-srv=${cfg.statusListenAddress}:${toString cfg.statusPort}"
    "--provided-by=${escapeShellArg cfg.providedBy}"
    (optionalString (cfg.pools != null) "--pools=${escapeShellArg (concatStringsSep "," cfg.pools)}")
    (optionalString (cfg.globalRateBps != null) "--global-rate=${toString cfg.globalRateBps}")
    (optionalString (cfg.perSessionRateBps != null) "--per-session-rate=${toString cfg.perSessionRateBps}")
  ];
in {
  options.services.syncthing.relay = {
    enable = mkEnableOption "Syncthing relay service";

    listenAddress = mkOption {
      type = types.str;
      default = "";
      description = ''
        Address to listen on for relay traffic.
      '';
    };

    port = mkOption {
      type = types.int;
      default = 22067;
      description = ''
        Port to listen on for relay traffic.
      '';
    };

    statusListenAddress = mkOption {
      type = types.str;
      default = "";
      description = ''
        Address to listen on for serving the relay status API.
      '';
    };

    statusPort = mkOption {
      type = types.int;
      default = 22070;
      description = ''
        Port to listen on for serving the relay status API.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to open the relay and status API ports in the firewall.
      '';
    };

    pools = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = ''
        Relay pools to join. If null, uses the default global pool.
      '';
    };

    providedBy = mkOption {
      type = types.str;
      default = "";
      description = ''
        Human-readable description of the provider of the relay (you).
      '';
    };

    globalRateBps = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = ''
        Global bandwidth rate limit in bytes per second.
      '';
    };

    perSessionRateBps = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = ''
        Per session bandwidth rate limit in bytes per second.
      '';
    };
  };

  config = mkIf cfg.enable {
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port cfg.statusPort ];
    };

    systemd.services.syncthing-relay = {
      description = "Syncthing relay service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        DynamicUser = true;
        StateDirectory = builtins.baseNameOf dataDirectory;

        Restart = "on-failure";
        ExecStart = "${pkgs.syncthing-relay}/bin/strelaysrv ${concatStringsSep " " relayOptions}";
      };
    };
  };
}
