{
  config,
  lib,
  secrets,
  ...
}:

let
  cfg = config.my.roles.nas-client;
in
{
  options.my.roles.nas-client = with lib; {
    enable = mkEnableOption "NAS client";
    mountPoint = mkOption {
      type = types.str;
      default = "/data";
      description = "Directory where the NAS will be mounted.";
    };
    server = mkOption {
      type = types.str;
      example = "nas.delroth.net";
      description = "Hostname of the server to connect to.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelModules = [
      "cifs"
      "cmac"
      "hmac"
      "md4"
      "md5"
      "sha256"
      "sha512"
    ];

    systemd.mounts = [
      {
        description = "Mount for NAS ${cfg.server}";
        what = "//${cfg.server}/data";
        where = cfg.mountPoint;
        options = "username=nas,password=${secrets.nasPassword},uid=1000,gid=1000,rw";
      }
    ];

    systemd.automounts = [
      {
        description = "Automount for NAS ${cfg.server}";
        where = cfg.mountPoint;
        wantedBy = [ "multi-user.target" ];
      }
    ];
  };
}
