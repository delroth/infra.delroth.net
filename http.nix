{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    package = pkgs.nginxMainline;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;

    sso = {
      enable = true;
      configuration = {
        listen = {
          addr = "127.0.0.1";
          port = 8082;
        };

        login = {
          title = "login.delroth.net";
          default_method = "simple";
          names = {
            simple = "Username / Password";
          };
        };

        providers = {
          simple = {
            users = import ./secrets/sso-users.nix;
          };
        };
      };
    };

    virtualHosts = let
      withSsl = vhost: vhost // {
        forceSSL = true;
        enableACME = true;
      };
      localReverseProxy = port: withSsl {
        locations."/" = {
          proxyPass = "http://localhost:${toString port}";
        };
      };
      localReverseProxyAddr = addr: withSsl {
        locations."/" = {
          proxyPass = "http://${addr}";
        };
      };
      localRoot = root: withSsl {
        locations."/" = {
          root = "${root}";
        };
      };
    in {

      # Used for ACME to generate a TLS cert for the MX.
      "${config.networking.hostName}" = withSsl {};

      "delroth.net" = localRoot "/srv/http/public";
      "japan2018.delroth.net" = localRoot "/srv/http/japan2018";

      "mon.delroth.net" = localReverseProxy config.services.grafana.port;
      "am.delroth.net" = localReverseProxy config.services.prometheus.alertmanager.port;
      "prom.delroth.net" = localReverseProxyAddr config.services.prometheus.listenAddress;

      # Used to bypass CORS for https://delroth.net/publibike/
      "publibike-api.delroth.net" = withSsl {
        locations."/" = {
          proxyPass = "https://api.publibike.ch:443";
          extraConfig = ''
            proxy_set_header Host api.publibike.ch;
            proxy_set_header Origin "";
            proxy_set_header Referer "";
          '';
        };
      };

    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
