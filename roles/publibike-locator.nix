{ config, lib, pkgs, ... }:

let
  cfg = config.my.roles.publibike-locator;
in {
  options.my.roles.publibike-locator = {
    enable = lib.mkEnableOption "Publibike Locator web app";
  };

  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts = {
      # Used to bypass CORS.
      "publibike-api.delroth.net" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          # Don't use the proxyPass option to avoid adding the recommended
          # proxy headers. We explicitly don't want them as they will re-add
          # Host and Origin with wrong values.
          extraConfig = ''
            proxy_pass https://api.publibike.ch:443;
            proxy_set_header Host api.publibike.ch;
            proxy_set_header Origin "";
            proxy_set_header Referer "";
            add_header Access-Control-Allow-Origin "https://delroth.net";
          '';
        };
      };

      "delroth.net" = {
        forceSSL = true;
        enableACME = true;
        locations."/publibike/" = {
          alias = "${pkgs.publibike-locator}/";
        };
      };
    };
  };
}
