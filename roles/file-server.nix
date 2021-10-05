{ config, lib, machineName, secrets, ... }:

let
  cfg = config.my.roles.file-server;
in {
  options.my.roles.file-server = with lib; {
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
      enableWinbindd = false;
      extraConfig = ''
        log level = 2
        logging = systemd

        server min protocol = SMB2
        smb encrypt = mandatory
        client signing = mandatory
        server signing = mandatory
      '';
      shares."${cfg.shareName}" = {
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
      allowedTCPPorts = [ 139 445 ];
      allowedUDPPorts = [ 137 138 ];
    };

    my.backup.extraPaths = [ cfg.root ];
  };
}
