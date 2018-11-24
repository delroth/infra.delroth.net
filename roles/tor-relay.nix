{ config, machineName, staging, ... }:

{
  services.tor = {
    enable = true;
    controlPort = 9051;
    relay = {
      enable = !staging;
      role = "relay";
      port = 143;
      nickname = "${builtins.replaceStrings [ "-" ] [ "" ] machineName}Delroth";
    };
  };

  networking.firewall.allowedTCPPorts = [config.services.tor.relay.port];
}
