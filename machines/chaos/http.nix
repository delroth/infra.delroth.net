{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:

{
  services.nginx = rec {
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
            users = builtins.mapAttrs (_: value: value.passwordHash) secrets.sso.users;

            mfa =
              builtins.mapAttrs
                (_: value: [
                  {
                    provider = "google";
                    attributes = {
                      secret = value.totpSecret;
                    };
                  }
                ])
                secrets.sso.users;

            groups = secrets.sso.groups;
          };
        };

        acl = {
          rule_sets = [
            {
              rules = [
                {
                  field = "x-application";
                  present = true;
                }
              ];
              allow = [ "@root" ];
            }
            {
              rules = [
                {
                  field = "x-application";
                  equals = "grafana";
                }
              ];
              allow = [ "@dashboard" ];
            }
          ];
        };
      };
    };

    virtualHosts =
      let
        withSsl =
          vhost:
          vhost
          // {
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

        withSso =
          { appName, vhost }:
          vhost
          // {
            extraConfig =
              (vhost.extraConfig or "")
              + ''
                error_page 401 = @error401;
              '';

            locations."/" = vhost.locations."/" // {
              extraConfig =
                (vhost.locations."/".extraConfig or "")
                + ''
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

        localRoot =
          root:
          withSsl {
            locations."/" = {
              root = "${root}";
            };
          };

        localReverseProxyAddr =
          addr:
          withSsl {
            locations."/" = {
              proxyPass = "http://${addr}";
              extraConfig = reverseProxyHeaders;
            };
          };
        localReverseProxy = port: localReverseProxyAddr "127.0.0.1:${toString port}";
      in
      {

        # Used for ACME to generate a TLS cert for the MX.
        "${config.my.networking.fqdn}" = withSsl { };

        "login.delroth.net" = localReverseProxy sso.configuration.listen.port;

        "delroth.net" = withSsl {
          extraConfig = ''
            error_page 404 /404.html;

            gzip on;
            gzip_types
              text/plain
              text/css
              text/js
              text/xml
              text/javascript
              application/javascript
              application/json
              application/xml
              application/rss+xml
              application/x-javascript
              image/svg+xml;

            location ~ ^/(css|js|images|fonts)/ {
              expires 30d;
              add_header Cache-Control "public";
              root ${pkgs.delroth-net-website};
            }
          '';

          locations."/" = {
            extraConfig = ''
              root ${pkgs.delroth-net-website};
              try_files $uri $uri/ @data;
            '';
          };

          locations."@data" = {
            root = "/srv/http/public";
          };

          locations."/.well-known/matrix/client" = {
            extraConfig = ''
              return 200 '{"m.homeserver": {"base_url": "https://matrix.delroth.net"}, "org.matrix.msc3575.proxy": {"url": "https://matrix-sync.delroth.net"}}';
              add_header Content-Type application/json;
              add_header Access-Control-Allow-Origin *;
            '';
          };
          locations."/.well-known/matrix/server" = {
            extraConfig = ''
              return 200 '{"m.server": "matrix.delroth.net:8448"}';
              add_header Content-Type application/json;
              add_header Access-Control-Allow-Origin *;
            '';
          };
          locations."/.well-known/host-meta" = {
            extraConfig = ''
              return 301 https://mastodon.delroth.net$request_uri;
            '';
          };
          locations."/.well-known/nodeinfo" = {
            extraConfig = ''
              return 301 https://mastodon.delroth.net$request_uri;
            '';
          };
        };
        "japan2018.delroth.net" = localRoot "/srv/http/japan2018";

        "mon.delroth.net" = withSso {
          appName = "grafana";
          vhost = localReverseProxy config.services.grafana.settings.server.http_port;
        };
        "am.delroth.net" = withSso {
          appName = "alertmanager";
          vhost = localReverseProxy config.services.prometheus.alertmanager.port;
        };
        "prom.delroth.net" = withSso {
          appName = "prometheus";
          vhost = localReverseProxy config.services.prometheus.port;
        };
        "syncthing.delroth.net" = withSso {
          appName = "syncthing";
          vhost = localReverseProxy 8384;
        };

        # Allow Grafana snapshot access without auth.
        "mon-public.delroth.net" =
          let
            vhost = (localReverseProxy config.services.grafana.settings.server.http_port).locations."/";
          in
          withSsl {
            locations."/api/snapshots" = vhost;
            locations."/dashboard/snapshot" = vhost;
            locations."/public" = vhost;
          };
      };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
