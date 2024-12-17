{
  config,
  lib,
  machineName,
  ...
}:

let
  cfg = config.my.roles.syncthing-relay;
in
{
  options.my.roles.syncthing-relay = {
    enable = lib.mkEnableOption "Syncthing Relay";
  };

  config = lib.mkIf cfg.enable {
    services.syncthing.relay = {
      enable = true;
      port = 22067;
      statusPort = 22070;

      providedBy = "delroth (${machineName})";

      globalRateBps = lib.mkDefault (20 * 1024 * 1024); # 20MB/s
      perSessionRateBps = lib.mkDefault (5 * 1024 * 1024); # 5MB/s
    };

    my.homenet.ip4TcpPortForward = [
      config.services.syncthing.relay.port
      config.services.syncthing.relay.statusPort
    ];
    networking.firewall.allowedTCPPorts = [
      config.services.syncthing.relay.port
      config.services.syncthing.relay.statusPort
    ];
  };
}
