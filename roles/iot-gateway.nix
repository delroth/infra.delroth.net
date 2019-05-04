{ config, lib, ... }:

let
  cfg = config.my.roles.iot-gateway;
  my = import ../.;
in {
  options.my.roles.iot-gateway = {
    enable = lib.mkEnableOption "IoT gateway";
  };

  config = lib.mkIf cfg.enable {
    services.home-assistant = {
      enable = true;

      config = {
        frontend = {};
        history = {};

        netatmo = {
          api_key = my.secrets.iot.netatmo.api_key;
          secret_key = my.secrets.iot.netatmo.secret_key;
          username = my.secrets.iot.netatmo.username;
          password = my.secrets.iot.netatmo.password;
        };
        prometheus = {};

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
  };
}
