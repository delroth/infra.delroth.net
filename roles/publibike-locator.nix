{ config, lib, publibike-locator, ... }:

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

            if ($http_origin ~* "^https://(publibike[.])?delroth[.]net$") {
              add_header Access-Control-Allow-Origin "$http_origin";
            }
          '';
        };
      };

      "delroth.net" = {
        forceSSL = true;
        enableACME = true;
        locations."/publibike/" = {
          alias = "${publibike-locator.packages.x86_64-linux.publibike-locator}/";
          extraConfig = ''
            add_header Cache-Control "no-cache, max-age=0";
          '';
        };
      };

      "publibike.delroth.net" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          alias = "${publibike-locator.packages.x86_64-linux.publibike-locator}/";
          extraConfig = ''
            add_header Cache-Control "no-cache, max-age=0";
          '';
        };
      };
    };
  };
}
