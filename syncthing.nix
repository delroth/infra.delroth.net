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
      openFirewall = true;

      providedBy = "delroth";

      globalRateBps = 20 * 1024 * 1024;  # 20MB/s
      perSessionRateBps = 5 * 1024 * 1024;  # 5MB/s
    };
  };
}
