{ config, lib, pkgs, ... }:

let
  cfg = config.my.networking.pmp;
in {
  options.my.networking.pmp = with lib; {
    publicPorts = mkOption {
      type = types.listOf types.port;
      default = [];
      description = ''
        List of TCP ports to try and reserve for public IPv4 routing via PMP.
      '';
    };
  };

  config = let
    mkService = port: {
      name = "pmp-${toString port}";
      value = {
        description = "PMP port mapping for port ${toString port}";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.libnatpmp}/bin/natpmpc -a ${toString port} ${toString port} tcp 600";
          DynamicUser = true;
        };
      };
    };
    mkTimer = port: {
      name = "pmp-${toString port}";
      value = {
        description = "PMP port mapping for port ${toString port} (timer)";
        wantedBy = [ "timers.target" ];
        requires = [ "network-online.target" ];
        timerConfig = {
          OnBootSec = "0";
          OnUnitActiveSec = "5min";
          Persistent = true;
        };
      };
    };
  in {
    systemd.services = builtins.listToAttrs (map mkService cfg.publicPorts);
    systemd.timers = builtins.listToAttrs (map mkTimer cfg.publicPorts);
  };
}
