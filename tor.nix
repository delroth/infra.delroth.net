{ config, pkgs, ... }:

{
  services.tor = {
    enable = true;
    controlPort = 9051;
    relay = {
      enable = true;
      role = "relay";
      port = 143;
      nickname = "Chaos";
    };
  };

  networking.firewall.allowedTCPPorts = [config.services.tor.relay.port];
}
