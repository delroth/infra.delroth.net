{ config, lib, machineName, secrets, ... }:

let
  cfg = config.my.roles.seedbox;

  hostname = "seedbox.delroth.net";

  transmissionPort = 9091;
in {
  options.my.roles.seedbox = with lib; {
    enable = mkEnableOption "Seedbox";
  };

  config = lib.mkIf cfg.enable {
    services.transmission = {
      enable = true;
      group = "nas";

      settings = {
        download-dir = "/data/seedbox/default";
        incomplete-dir = "/data/seedbox/incomplete";

        rpc-enabled = true;
        rpc-port = transmissionPort;
        rpc-authentication-required = true;

        rpc-username = "delroth";
        rpc-password = secrets.transmissionPassword;

        # Proxied behind nginx.
        rpc-whitelist-enabled = true;
        rpc-whitelist = "127.0.0.1";
      };
    };

    services.nginx.virtualHosts."${hostname}" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString transmissionPort}";
      };
    };
  };
}
