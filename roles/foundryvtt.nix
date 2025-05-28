{ config, lib, pkgs, secrets, ... }:

let
  cfg = config.my.roles.foundryvtt;

  hostname = "foundry.delroth.net";
  port = 30000;
  version = "13.342";
  nodejs = pkgs.nodejs_24;

  dataPath = "/var/lib/foundryvtt";

  upstreamArchive = pkgs.fetchurl {
    url = "https://delroth.net/foundryvtt-${version}-${secrets.foundryvtt.downloadUrlSecret}.zip";
    hash = "sha256-6iyH7+62WC08VSw2MzA/iX7Xg9nRUsE57oBifnPPThw=";
  };

  pkg = pkgs.runCommand "foundryvtt-${version}" {} ''
    mkdir $out && cd $out
    ${lib.getExe pkgs.unzip} ${upstreamArchive}
  '';

  settingsJson = (pkgs.formats.json {}).generate "foundryvtt-settings.json" {
    inherit hostname port;
    proxyPort = 443;
    upnp = false;
    routePrefix = null;
    telemetry = true;
  };
in {
  options.my.roles.foundryvtt = {
    enable = lib.mkEnableOption "FoundryVTT server";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.foundryvtt = {
      description = "FoundryVTT server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Restart = "always";
        DynamicUser = true;

        WorkingDirectory = "${pkg}";
        StateDirectory = "foundryvtt";
      };

      preStart = ''
        cd ${dataPath}
        mkdir -p Config
        cd Config
        echo -n "${secrets.foundryvtt.adminPasswordHash}" > admin.txt
        test -f options.json || echo '{}' > options.json
        ${lib.getExe pkgs.jq} -s '.[0] * .[1]' options.json ${settingsJson} > options.json.new
        mv options.json.new options.json
      '';

      script = ''
        ${lib.getExe nodejs} main.js --dataPath=${dataPath}
      '';
    };

    services.nginx.virtualHosts."${hostname}" = {
      forceSSL = true;
      enableACME = true;

      extraConfig = ''
        client_max_body_size 256m;
      '';

      locations."/" = {
        proxyPass = "http://127.0.0.1:${port}";
        proxyWebsockets = true;
      };
    };
  };
}
