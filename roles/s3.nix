{ config, lib, pkgs, secrets, ... }:

let
  cfg = config.my.roles.s3;

  apiPort = 3900;
  rpcPort = 3901;
  webPort = 3902;
  adminPort = 3903;
in {
  options.my.roles.s3 = with lib; {
    enable = mkEnableOption "S3 server";
    dataRoot = mkOption {
      type = types.str;
      description = "Location where to store the S3 data.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.garage = {};
    users.users.garage = {
      group = "garage";
      isSystemUser = true;
    };

    services.garage = {
      enable = true;

      package = pkgs.garage_1_x;

      settings = {
        data_dir = cfg.dataRoot;

        replication_factor = 1;

        rpc_bind_addr = "[::]:${rpcPort}";
        rpc_secret = secrets.s3.rpc_secret;

        s3_api = {
          api_bind_addr = "127.0.0.1:${apiPort}";
          s3_region = "garage";
          root_domain = "s3.delroth.net";
        };

        s3_web = {
          bind_addr = "127.0.0.1:${webPort}";
          root_domain = "s3-web.delroth.net";
        };

        admin = {
          api_bind_addr = "127.0.0.1:${adminPort}";
          admin_token = secrets.s3.admin_token;
        };
      };
    };

    systemd.services.garage.serviceConfig = {
      User = "garage";
      ReadWriteDirectories = [ cfg.dataRoot ];
      TimeoutSec = 300;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataRoot} 0770 garage garage - -"
    ];

    my.backup.extraExclude = [ cfg.dataRoot ];

    services.nginx.appendConfig = ''
      worker_processes auto;
    '';

    services.nginx.eventsConfig = ''
      worker_connections 8192;
    '';

    services.nginx.virtualHosts = {
      "s3.delroth.net" = {
        forceSSL = true;
        useACMEHost = "s3.delroth.net";

        serverAliases = [ "~^([^.]*)[.]s3[.]delroth[.]net$" ];

        locations."/" = {
          proxyPass = "http://127.0.0.1:${apiPort}";
          extraConfig = ''
            proxy_max_temp_file_size 0;
            client_max_body_size 5G;
          '';
        };
      };

      "s3-web.delroth.net" = {
        forceSSL = true;
        useACMEHost = "s3-web.delroth.net";

        serverAliases = [ "~^([^.]*)[.]s3-web[.]delroth[.]net$" ];

        locations."/" = {
          proxyPass = "http://127.0.0.1:${webPort}";
        };
      };

      # Special domain serving setup for forkos.
      "cache.forkos.org" = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${webPort}";
          extraConfig = ''
            proxy_set_header Host bagel-cache.s3-web.delroth.net;
          '';
        };
      };
    };

    security.acme.certs = let
      wildcardCert = domain: {
        "${domain}" = {
          extraDomainNames = [ "*.${domain}" ];
          group = "nginx";

          dnsProvider = "rfc2136";
          environmentFile = pkgs.writeText "rfc2136-${domain}-env" ''
            RFC2136_NAMESERVER=ns.delroth.net
            RFC2136_TSIG_KEY=s3-role
            RFC2136_TSIG_ALGORITHM=${secrets.dnsupdate.s3-role.algo}.
            RFC2136_TSIG_SECRET=${secrets.dnsupdate.s3-role.secret}
          '';
        };
      };
    in (
      (wildcardCert "s3.delroth.net") //
      (wildcardCert "s3-web.delroth.net")
    );
  };
}
