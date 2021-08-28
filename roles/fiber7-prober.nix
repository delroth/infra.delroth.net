{ config, lib, pkgs, ... }:

let
  cfg = config.my.roles.fiber7-prober;
in {
  options.my.roles.fiber7-prober = with lib; {
    enable = mkEnableOption "Fiber7 prober (https://prober7.zekjur.net/)";

    probeId = mkOption {
      type = types.str;
      example = "0x12345678";
      description = ''
        ID of the probe to run.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.fiber7-prober = {
      description = "Fiber7 prober (probe id: ${cfg.probeId})";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "-${pkgs.curl}/bin/curl -s -o /dev/null http://prober7-sink.zekjur.net:42070/lightprobe/${cfg.probeId}";
        DynamicUser = true;
      };
    };

    systemd.timers.fiber7-prober = {
      description = "Fiber7 prober (timer, probe id: ${cfg.probeId})";
      wantedBy = [ "timers.target" ];
      requires = [ "network-online.target" ];
      timerConfig = {
        OnCalendar = "minutely";
        Persistent = true;
      };
    };
  };
}
