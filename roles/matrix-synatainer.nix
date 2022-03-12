{ config, lib, pkgs, secrets, ... }:

let
  cfg = config.my.roles.matrix-synatainer;

  synatainer = pkgs.fetchgit {
    url = "https://gitlab.com/mb-saces/synatainer";
    rev = "50b4664ee358292c7d3b3a9eb9a946e61d84ad09";
    sha256 = "sha256-pBafUK3SYfJq8iQUf9cdM8KBTDaHiNRoYZXiOy4T8u8=";
  };


  synatainerUnit = { name, description, frequency, script }: {
    systemd.services."synatainer-${name}" = {
      description = "Synatainer: ${description}";

      requires = [ "matrix-synapse.service" ];

      environment = {
        BEARER_TOKEN = secrets.matrix.adminToken;
        SYNAPSE_HOST = "http://127.0.0.1:11339";
        DB_HOST = "/run/postgresql";
        DB_NAME = "matrix-synapse";
        DB_USER = "matrix-synapse";
        PGPASSWORD = "";
      };

      path = [
        pkgs.curl
        pkgs.jq
        pkgs.matrix-synapse-tools.rust-synapse-compress-state
        pkgs.postgresql
      ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${synatainer}/scripts/${script}";
        User = "matrix-synapse";
      };
    };

    systemd.timers."synatainer-${name}" = {
      description = "Synatainer timer: ${description}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = frequency;
        Persistent = true;
      };
    };
  };
in {
  options.my.roles.matrix-synatainer = {
    enable = lib.mkEnableOption "Matrix Synatainer";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (synatainerUnit {
      name = "auto-compress";
      description = "auto compress";
      script = "autocompressor-big.sh";
      frequency = "weekly";
    })
    (synatainerUnit {
      name = "purge-remote-cache";
      description = "purge old remote cache files";
      script = "remote_cache_purge.sh";
      frequency = "daily";
    })
    (synatainerUnit {
      name = "purge-rooms-no-local-members";
      description = "purge rooms with no local members";
      script = "purge_rooms_no_local_members.sh";
      frequency = "daily";
    })
    (synatainerUnit {
      name = "vacuum-db";
      description = "vacuum postgresql database";
      script = "vacuum-db.sh";
      frequency = "weekly";
    })
  ]);
}
