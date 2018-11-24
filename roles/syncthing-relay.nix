{ config, lib, machineName, staging, ...}:

{
  services.syncthing.relay = {
    enable = true;
    port = 22067;
    statusPort = 22070;

    # Do not relay in staging.
    pools = lib.mkIf staging [];

    providedBy = "delroth (${machineName})";

    globalRateBps = 20 * 1024 * 1024;  # 20MB/s
    perSessionRateBps = 5 * 1024 * 1024;  # 5MB/s
  };

  networking.firewall.allowedTCPPorts = [
    config.services.syncthing.relay.port
    config.services.syncthing.relay.statusPort
  ];
}
