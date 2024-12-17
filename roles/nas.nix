{
  config,
  lib,
  machineName,
  secrets,
  ...
}:

let
  cfg = config.my.roles.nas;
in
{
  options.my.roles.nas = with lib; {
    enable = mkEnableOption "File server";
    root = mkOption {
      type = types.str;
      description = "Root directory for file serving.";
    };
    shareName = mkOption {
      type = types.str;
      description = "Publicly visible name for the file share.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.nas.gid = 5000;
    users.users.nas = {
      uid = 5000;
      group = "nas";
      password = secrets.nasPassword;
      isSystemUser = true;
    };

    services.samba = {
      enable = true;
      winbindd.enable = false;
      settings.global = {
        "log level" = 1;
        "logging" = "systemd";

        "server min protocol" = "SMB3";
        "smb encrypt" = "required";
        "client signing" = "mandatory";
        "server signing" = "mandatory";

        "socket options" = "TCP_NODELAY IPTOS_LOWDELAY";
        "use sendfile" = true;
      };

      settings."${cfg.shareName}" = {
        path = cfg.root;
        comment = "Serving from ${machineName}:${cfg.root}";
        "read only" = false;
        "force create mode" = "0660";
        "force directory mode" = "2770";
        "force user" = "nas";
        "force group" = "nas";
      };
    };

    networking.firewall = {
      allowedTCPPorts = [
        139
        445
      ];
      allowedUDPPorts = [
        137
        138
      ];
    };

    my.backup.extraPaths = [ cfg.root ];
  };
}
