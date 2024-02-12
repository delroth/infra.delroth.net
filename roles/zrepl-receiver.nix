{
  config,
  lib,
  ...
}:

# TODO: make this a bit more generic, right now it's very hardcoded for the
# NixOS / haumea backup case...

let
  cfg = config.my.roles.zrepl-receiver;
in
{
  options.my.roles.zrepl-receiver = {
    enable = lib.mkEnableOption "zrepl receiver";
  };

  config = lib.mkIf cfg.enable {
    services.zrepl = {
      enable = true;

      settings = {
        global = {
          logging = [
            {
              type = "syslog";
              level = "info";
              format = "human";
            }
          ];
        };

        jobs = [
          {
            name = "nixos-backups";
            type = "sink";
            serve = {
              type = "stdinserver";
              client_identities = [ "haumea" ];
            };
            recv.placeholder.encryption = "off";
            root_fs = "ds";
          }
        ];
      };
    };

    users.users.zrepl = {
      group = "zrepl";
      isSystemUser = true;
      useDefaultShell = true;
      openssh.authorizedKeys.keys = [
        "command=\"zrepl stdinserver haumea\",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyyr/4fMKQ1fwa5DjFVIHQLchr4EKcOWEI++gYBTbWF"
      ];
    };
    users.groups.zrepl = {};

    systemd.services.zrepl.serviceConfig = {
      RuntimeDirectoryMode = "0770";
      Group = "zrepl";
      UMask = "0002";
    };
  };
}
