{ config, lib, machineName, ... }:

let
  my = import ../.;
in {
  options.my.backup.extraPaths = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      Extra system paths to include in daily backups.
    '';
  };

  config = lib.mkIf (my.secrets.backup.pass ? "${machineName}") {
    services.borgbackup.jobs.default = {
      repo = "${my.secrets.backup.location}/${machineName}";
      doInit = true;
      archiveBaseName = machineName;

      paths = [
        "/home"
        "/root"
        "/var/lib"
        "/var/log"
      ] ++ config.my.backup.extraPaths;

      exclude = [
        "/home/*/.cache"
        "/home/*/.local/share/Steam"

        # Causes backups to fail due to temp files appearing / disappearing.
        "/var/lib/tor/diff-cache"
      ];

      extraCreateArgs = "--one-file-system";

      startAt = "daily";
      prune = {
        prefix = "";
        keep = {
          within = "1d";
          daily = 7;
          weekly = 4;
          monthly = 6;
        };
      };

      compression = "auto,zstd";
      encryption = {
        mode = "repokey-blake2";
        passphrase = my.secrets.backup.pass."${machineName}";
      };

      # SSH insists on having secure unix permissions on SSH private keys. We
      # don't really care since these are single user systems.
      preHook = ''
        cp ${my.secrets.backup.sshKey} /tmp/backup-ssh-key
        chmod 600 /tmp/backup-ssh-key
      '';

      environment = {
        BORG_RSH = "ssh -i /tmp/backup-ssh-key -o UserKnownHostsFile=${my.secrets.backup.sshHostPub}";
      };
    };

    # To allow mounting remote backups.
    boot.kernelModules = [ "fuse" ];
  };
}
