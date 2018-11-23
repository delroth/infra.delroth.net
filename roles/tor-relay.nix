{ config, machineName, ... }:

{
  services.tor = {
    enable = true;
    controlPort = 9051;
    relay = {
      enable = true;
      role = "relay";
      port = 143;
      nickname = "${machineName}Delroth";
    };
  };

  networking.firewall.allowedTCPPorts = [config.services.tor.relay.port];
}
