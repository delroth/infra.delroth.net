{ config, pkgs, secrets, ... }:

{
  services.nginx = rec {
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

        cookie = {
          domain = ".delroth.net";
          expire = 3600 * 24 * 30;
          secure = true;
          authentication_key = secrets.sso.key;
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
            users =
              builtins.mapAttrs
                (_: value: value.passwordHash)
                secrets.sso.users;

            mfa =
              builtins.mapAttrs
                (_: value: [{
                  provider = "google";
                  attributes = { secret = value.totpSecret; };
                }])
                secrets.sso.users;

            groups = secrets.sso.groups;
          };
        };

        acl = {
          rule_sets = [
            {
              rules = [ { field = "x-application"; present = true; } ];
              allow = [ "@root" ];
            }
            {
              rules = [ { field = "x-application"; equals = "grafana"; } ];
              allow = [ "@dashboard" ];
            }
          ];
        };
      };
    };

    virtualHosts = let
      withSsl = vhost: vhost // {
        forceSSL = true;
        enableACME = true;
      };

      reverseProxyHeaders = ''
        proxy_set_header X-Original-URL $request_uri;
        proxy_set_header X-Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';

      withSso = {appName, vhost}: vhost // {
        extraConfig = (vhost.extraConfig or "") + ''
          error_page 401 = @error401;
        '';

        locations."/" = vhost.locations."/" // {
          extraConfig = (vhost.locations."/".extraConfig or "") + ''
            auth_request /sso-auth;

            auth_request_set $username $upstream_http_x_username;
            proxy_set_header X-User $username;

            auth_request_set $cookie $upstream_http_set_cookie;
            add_header Set-Cookie $cookie;
          '';
        };

        locations."/sso-auth" = {
          proxyPass = "http://localhost:${toString sso.configuration.listen.port}/auth";
          extraConfig = ''
            internal;

            proxy_pass_request_body off;
            proxy_set_header Content-Length "";

            proxy_set_header X-Application "${appName}";
            ${reverseProxyHeaders}
          '';
        };

        locations."@error401" = {
          extraConfig = ''
            return 302 https://login.delroth.net/login?go=$scheme://$http_host$request_uri;
          '';
        };
      };

      localRoot = root: withSsl {
        locations."/" = {
          root = "${root}";
        };
      };

      localReverseProxyAddr = addr: withSsl {
        locations."/" = {
          proxyPass = "http://${addr}";
          extraConfig = reverseProxyHeaders;
        };
      };
      localReverseProxy = port: localReverseProxyAddr "localhost:${toString port}";
    in {

      # Used for ACME to generate a TLS cert for the MX.
      "${config.networking.hostName}" = withSsl {};

      "login.delroth.net" = localReverseProxy sso.configuration.listen.port;

      "delroth.net" = localRoot "/srv/http/public";
      "japan2018.delroth.net" = localRoot "/srv/http/japan2018";

      "mon.delroth.net" = withSso {
        appName = "grafana";
        vhost = localReverseProxy config.services.grafana.port;
      };
      "am.delroth.net" = withSso {
        appName = "alertmanager";
        vhost = localReverseProxy config.services.prometheus.alertmanager.port;
      };
      "prom.delroth.net" = withSso {
        appName = "prometheus";
        vhost = localReverseProxyAddr config.services.prometheus.listenAddress;
      };
      "syncthing.delroth.net" = withSso {
        appName = "syncthing";
        vhost = localReverseProxy 8384;
      };

      # Allow Grafana snapshot access without auth.
      "mon-public.delroth.net" = let
        vhost = (localReverseProxy config.services.grafana.port).locations."/";
      in withSsl {
        locations."/api/snapshots" = vhost;
        locations."/dashboard/snapshot" = vhost;
        locations."/public" = vhost;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
