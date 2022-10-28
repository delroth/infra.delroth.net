{ config, lib, secrets, ... }:

let
  cfg = config.my.roles.backup-receiver;
in {
  options.my.roles.backup-receiver = with lib; {
    enable = mkEnableOption "Backup receiver";

    basePath = mkOption {
      type = types.str;
      default = "/data/backups";
      description = ''
        Base destination path for received backups.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.borgbackup.repos = let
      repos =
        builtins.mapAttrs
        (name: repocfg: {
          path = "${cfg.basePath}/${name}";
          authorizedKeys = repocfg.keys;
          quota = repocfg.quota;
        })
        secrets.backup.repos;
    in
      repos;

    # Don't backup the backups.
    my.backup.extraExclude = [ cfg.basePath ];
  };
}
