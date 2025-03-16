{
  config,
  lib,
  secrets,
  ...
}:

let
  cfg = config.my.roles.iot-gateway;

  hostname = "hass.delroth.net";
  port = 8123;
in
{
  options.my.roles.iot-gateway = {
    enable = lib.mkEnableOption "IoT gateway";
  };

  config = lib.mkIf cfg.enable {
    services.home-assistant = {
      enable = true;

      extraComponents = [
        "aranet"
        "lifx"
        "xiaomi_miio"
      ];

      config = {
        default_config = {};

        http = {
          server_host = "127.0.0.1";
          server_port = port;
          base_url = "https://${hostname}";
          use_x_forwarded_for = true;
          trusted_proxies = [ "127.0.0.1" ];
        };
        frontend = { };

        prometheus = {
          # Handled separately.
          requires_auth = false;
        };
      };
    };

    services.nginx.virtualHosts."${hostname}" = rec {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://localhost:${toString port}";
        extraConfig = ''
          proxy_http_version 1.1;
          proxy_redirect http:// https://;
          proxy_set_header Host $host;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "Upgrade";
          proxy_set_header X-Real-IP $remote_addr;
          proxy_buffering off;
        '';
      };

      locations."/api/prometheus" = locations."/" // {
        basicAuth = {
          prometheus = secrets.nodeMetricsKey;
        };
      };
    };

    hardware.bluetooth.enable = true;
  };
}
