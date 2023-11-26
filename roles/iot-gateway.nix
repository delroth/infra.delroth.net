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

      config = {
        http = {
          server_host = "127.0.0.1";
          server_port = port;
          base_url = "https://${hostname}";
          use_x_forwarded_for = true;
          trusted_proxies = [ "127.0.0.1" ];
        };
        frontend = { };
        history = { };

        netatmo = {
          api_key = secrets.iot.netatmo.api_key;
          secret_key = secrets.iot.netatmo.secret_key;
          username = secrets.iot.netatmo.username;
          password = secrets.iot.netatmo.password;
        };
        prometheus = { };

        sensor = [
          {
            platform = "fitbit";
            monitored_resources = [
              "activities/calories"
              "activities/distance"
              "activities/floors"
              "activities/heart"
              "activities/steps"
              "body/weight"
              "devices/battery"
              "sleep/efficiency"
            ];
          }
          { platform = "netatmo"; }
        ];
      };
    };

    services.nginx.virtualHosts."${hostname}" = {
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
    };
  };
}
