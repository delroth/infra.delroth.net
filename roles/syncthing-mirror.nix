{
  config,
  lib,
  machineName,
  pkgs,
  secrets,
  ...
}:

let
  cfg = config.my.roles.syncthing-mirror;

  devices =
    builtins.mapAttrs
      (name: info: {
        inherit name;
        id = info.id;
        introducer = true;
      })
      secrets.syncthing;
in
{
  options.my.roles.syncthing-mirror = {
    enable = lib.mkEnableOption "Syncthing mirror role";
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
      user = "delroth";
      group = "users";
      dataDir = "/home/delroth/.syncthing";

      cert = "${pkgs.writeText "syncthing-cert.pem" secrets.syncthing."${machineName}".cert}";
      key = "${pkgs.writeText "syncthing-key.pem" secrets.syncthing."${machineName}".key}";

      settings = {
        inherit devices;

        folders."/home/delroth/Dropbox" = {
          id = "75wdo-3odel";
          label = "Dropbox";
          devices = builtins.attrNames devices;
          versioning = {
            type = "staggered";
            params = {
              cleanInterval = "3600";
              maxAge = "31536000"; # 365d
            };
          };
        };
      };
    };
  };
}
