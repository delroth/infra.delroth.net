{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:

let
  cfg = config.my.roles.matrix-signal-bridge;

  dataDir = "/var/lib/mautrix-signal";
  settingsFile = "${dataDir}/config.json";
  registrationFile = "${dataDir}/signal-registration.yaml";
  port = 29328;

  settings = {
    homeserver = {
      address = "https://matrix.delroth.net";
      domain = "delroth.net";
    };

    appservice = {
      address = "https://matrix-signal.delroth.net";
      hostname = "127.0.0.1";
      inherit port;

      database = "sqlite:///db.sqlite";

      as_token = secrets.matrix.signal.as_token;
      hs_token = secrets.matrix.signal.hs_token;
    };

    bridge = {
      permissions = {
        "@delroth:delroth.net" = "admin";
      };
    };
  };

  settingsFileOrig = (pkgs.formats.json { }).generate "mautrix-signal.json" settings;
in
{
  options.my.roles.matrix-signal-bridge = {
    enable = lib.mkEnableOption "Matrix Signal Bridge";
  };

  config = lib.mkIf cfg.enable {
    services.signald.enable = true;

    users.users.mautrix-signal = {
      isSystemUser = true;
      group = "mautrix-signal";
      home = dataDir;
      extraGroups = [ config.services.signald.group ];
    };
    users.groups.mautrix-signal = { };

    systemd.services.mautrix-signal = {
      description = "Signal bridge for Matrix";

      wantedBy = [ "multi-user.target" ];
      wants = [
        "network-online.target"
        "matrix-synapse.service"
      ];
      after = [
        "network-online.target"
        "matrix-synapse.service"
      ];

      preStart = ''
        cp ${settingsFileOrig} ${settingsFile}
        chmod 600 ${settingsFile}

        if [ ! -f '${registrationFile}' ]; then
          ${pkgs.mautrix-signal}/bin/mautrix-signal \
            --generate-registration \
            --config='${settingsFile}' \
            --registration='${registrationFile}'
        fi
        chmod 640 '${registrationFile}'
        chown mautrix-signal:matrix-synapse '${registrationFile}'
      '';

      serviceConfig = {
        Type = "simple";
        User = "mautrix-signal";
        Group = "mautrix-signal";
        UMask = 27;
        WorkingDirectory = dataDir;
        ExecStart = ''
          ${pkgs.mautrix-signal}/bin/mautrix-signal \
            --config='${settingsFile}' \
            --registration='${registrationFile}'
        '';
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };

    services.matrix-synapse.settings.app_service_config_files = [ registrationFile ];

    services.nginx = {
      enable = true;

      virtualHosts."matrix-signal.delroth.net" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://127.0.0.1:${toString port}";
      };
    };
  };
}
