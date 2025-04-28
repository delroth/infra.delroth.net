{ config, lib, secrets, ... }:

let
  cfg = config.my.roles.print-server;

  hostname = "print-server.delroth.net";
in {
  options.my.roles.print-server = with lib; {
    enable = mkEnableOption "Print server";
    printerName = mkOption {
      type = types.str;
      description = "Name of the printer to configure";
    };
  };

  config = lib.mkIf cfg.enable {
    services.printing = {
      enable = true;
      defaultShared = true;
      browsing = true;
      listenAddresses = [];  # UNIX socket only

      # Override default auth policy from the NixOS module. Note that this is
      # only accessible through either a local user (via the UNIX socket) or an
      # auth'd remote user.
      extraConf = lib.mkForce ''
        <Location />
          Order deny,allow
        </Location>

        <Location /admin>
          Order allow,deny
        </Location>

        <Policy default>
          <Limit All>
            Order allow,deny
          </Limit>
        </Policy>
      '';
    };

    services.nginx.virtualHosts."${hostname}" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        extraConfig = ''
          # CUPS is dumb, fake being localhost because otherwise it refuses to
          # serve the requests.
          proxy_pass http://unix:/run/cups/cups.sock;
          proxy_set_header Host localhost;
          proxy_hide_header Authorization;

          proxy_buffering off;
          client_max_body_size 256m;
        '';

        basicAuth = {
          print = secrets.printKey;
        };
      };
    };
  };
}
