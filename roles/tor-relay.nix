{ config, lib, machineName, ... }:

let
  cfg = config.my.roles.tor-relay;
in {
  options.my.roles.tor-relay = {
    enable = lib.mkEnableOption "Tor Relay";
  };

  config = lib.mkIf cfg.enable {
    services.tor = {
      enable = true;
      controlPort = 9051;
      relay = {
        enable = true;
        role = "relay";
        port = 143;
        nickname = "${builtins.replaceStrings [ "-" ] [ "" ] machineName}Delroth";
      };
    };

    networking.firewall.allowedTCPPorts = [config.services.tor.relay.port];

    # Monitoring.
    services.prometheus.exporters.tor = {
      enable = true;
      torControlPort = config.services.tor.controlPort;
      listenAddress = "127.0.0.1";
      port = 9130;
    };
  };
}
