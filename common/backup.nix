{ config, lib, machineName, pkgs, secrets, ... }:

{
  options.my.backup = with lib; {
    extraPaths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Extra system paths to include in daily backups.
      '';
    };

    extraExclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Extra system paths to exclude from daily backups.
      '';
    };
  };

  config = lib.mkIf (secrets.backup.pass ? "${machineName}") {
    services.borgbackup.jobs.default = {
      repo = "${secrets.backup.location}/${machineName}";
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

        # List of "heavy" files which are fine to exclude from offsite backups.
        "*.mkv" "*.avi" "*.mp4" "*.mp3" "*.ogg" "*.flac" "*.VOB"
        "*.iso" "*.gcm" "*.gcz" "*.cso" "*.sdc"
        "*.vdi" "*.qcow2" "*.vmdk" "*.ova"
      ] ++ config.my.backup.extraExclude;

      extraCreateArgs = "--one-file-system --stats";

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
        passphrase = secrets.backup.pass."${machineName}";
      };

      preHook = ''
        # SSH insists on having secure unix permissions on SSH private keys. We
        # don't really care since these are single user systems.
        cp ${secrets.backup.sshKey} /tmp/backup-ssh-key
        chmod 600 /tmp/backup-ssh-key

        # Ignore warning return code.
        realBorg="$(${pkgs.which}/bin/which borg)"
        borg() {
          returnCode=0
          "$realBorg" "$@" || returnCode=$?

          if [[ $returnCode -eq 1 ]]; then
            return 0
          else
            return $returnCode
          fi
        }
      '';

      environment = {
        BORG_RSH = "ssh -i /tmp/backup-ssh-key -o UserKnownHostsFile=${secrets.backup.sshHostPub}";
      };
    };

    systemd.services.borgbackup-job-default.wants = [ "network-online.target" ];

    # Be a bit more resilient to transient network failures.
    systemd.services.borgbackup-job-default.serviceConfig.Restart = "on-failure";

    # To allow mounting remote backups.
    boot.kernelModules = [ "fuse" ];
  };
}
