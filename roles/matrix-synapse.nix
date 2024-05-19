{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:

let
  cfg = config.my.roles.matrix-synapse;

  federationPort = {
    public = 8448;
    private = 11338;
  };
  clientPort = {
    public = 443;
    private = 11339;
  };
  syncPort = 8002;

  domain = "delroth.net";

  acmeDirectory = config.security.acme.directory;
in
{
  options.my.roles.matrix-synapse = {
    enable = lib.mkEnableOption "Matrix Synapse";
  };

  config = lib.mkIf cfg.enable {
    services.postgresql.enable = true;

    services.matrix-synapse = {
      enable = true;

      settings = {
        server_name = domain;
        public_baseurl = "https://matrix.${domain}";

        registration_shared_secret = secrets.matrix.registrationSharedSecret;

        listeners = [
          # Federation
          {
            bind_addresses = [ "127.0.0.1" ];
            port = federationPort.private;
            tls = false; # Terminated by nginx.
            x_forwarded = true;
            resources = [
              {
                names = [ "federation" ];
                compress = false;
              }
            ];
          }

          # Client
          {
            bind_addresses = [ "127.0.0.1" ];
            port = clientPort.private;
            tls = false; # Terminated by nginx.
            x_forwarded = true;
            resources = [
              {
                names = [ "client" ];
                compress = false;
              }
            ];
          }
        ];
      };

      sliding-sync = {
        enable = true;
        environmentFile = "/dev/null";
        settings.SYNCV3_BINDADDR = "127.0.0.1:${toString syncPort}";
        settings.SYNCV3_SECRET = secrets.matrix.syncSecret;
        settings.SYNCV3_SERVER = "https://matrix.${domain}";
      };
    };

    services.nginx = {
      virtualHosts =
        let
          passToMatrix = port: { proxyPass = "http://127.0.0.1:${toString port}"; };
        in
        {
          "matrix.${domain}" = {
            forceSSL = true;
            enableACME = true;

            locations."/" = passToMatrix clientPort.private;
          };

          "matrix-sync.${domain}" = {
            forceSSL = true;
            enableACME = true;

            locations."/" = passToMatrix syncPort;
          };

          "matrix.${domain}_federation" = rec {
            onlySSL = true;
            serverName = "matrix.${domain}";
            useACMEHost = serverName;

            listen = [
              {
                addr = "0.0.0.0";
                port = federationPort.public;
                ssl = true;
              }
              {
                addr = "[::]";
                port = federationPort.public;
                ssl = true;
              }
            ];

            locations."/" = passToMatrix federationPort.private;
          };
        };
    };

    # For administration tools.
    environment.systemPackages = [ pkgs.matrix-synapse ];

    networking.firewall.allowedTCPPorts = [
      clientPort.public
      federationPort.public
    ];
  };
}
