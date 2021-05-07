{ config, lib, pkgs, ... }:

let
  cfg = config.my.roles.matrix-client;

  domain = "delroth.net";

  my-element-web = pkgs.element-web.override {
    conf = {
      default_server_config = {
        "m.homeserver" = {
          base_url = "https://matrix.delroth.net";
          server_name = "delroth.net";
        };
        "m.identity_server" = {
          base_url = "https://vector.im";
        };
      };
      brand = "${domain} Element";
      disable_guests = true;
    };
  };
in {
  options.my.roles.matrix-client = {
    enable = lib.mkEnableOption "Matrix client (Element)";
  };

  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts."element.${domain}" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        root = "${my-element-web}";
      };
    };
  };
}
