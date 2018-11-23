{ config, pkgs, ... }:

{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "delroth";
    group = "users";
    dataDir = "/home/delroth/.syncthing";

    relay = {
      enable = true;
      port = 22067;
      statusPort = 22070;

      providedBy = "delroth";

      globalRateBps = 20 * 1024 * 1024;  # 20MB/s
      perSessionRateBps = 5 * 1024 * 1024;  # 5MB/s
    };
  };

  networking.firewall.allowedTCPPorts = [
    config.services.syncthing.relay.port
    config.services.syncthing.relay.statusPort
  ];
}
