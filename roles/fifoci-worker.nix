{
  config,
  lib,
  machineName,
  pkgs,
  secrets,
  ...
}:

let
  cfg = config.my.roles.fifoci-worker;

  masterAddr = "buildbot.dolphin-emu.org:9989";
  workerPassword = secrets.buildbot-worker."${machineName}".password;

  homeDir = "/srv/fifoci-worker";
  workerDir = "${homeDir}/worker";

  # fifociShell is a shell with the environment required to build Dolphin.
  # Setting up a development environment with NixOS is tricky, since this
  # requires running package hooks to get e.g. the proper PKG_CONFIG_PATH and
  # more.
  fifociShell =
    let
      dol = pkgs.dolphinEmuMaster;
      inputAttrs = [
        "buildInputs"
        "nativeBuildInputs"
        "propagatedBuildInputs"
        "propagatedNativeBuildInputs"
      ];
      deps =
        lib.concatMapStringsSep "\n"
          (
            attr:
            let
              l = dol."${attr}";
              spaceSeparated = lib.concatMapStringsSep " " (drv: "${drv}") l;
            in
            ''${attr}="${spaceSeparated}"''
          )
          inputAttrs;
    in
    pkgs.runCommand "fifoci-shell"
      {
        passthru = {
          shellPath = "/bin/fifoci-shell";
        };
      }
      ''
        mkdir -p $out/bin $out/share

        cat > $out/bin/fifoci-shell <<EOF
        #! /bin/sh
        rc=$out/share/rcfile
        BASH_ENV=\$rc exec ${pkgs.bashInteractive}/bin/bash --rcfile \$rc "\$@"
        EOF
        chmod +x $out/bin/fifoci-shell

        # Lifted from the nix-shell implementation.
        export NIX_BUILD_TOP=/tmp
        export NIX_STORE=/nix/store
        export IN_NIX_SHELL=impure
        export NIX_ENFORCE_PURITY=0

        ${deps}

        source ${pkgs.stdenv}/setup

        unset SSL_CERT_FILE NIX_SSL_CERT_FILE HOME PWD TMP TMPDIR TEMPDIR TEMP

        ${pkgs.coreutils}/bin/env |
          ${pkgs.gnused}/bin/sed -r 's/^([^=]+)=(.*)$/export \1="\2"/'> $out/share/rcfile

        ${pkgs.gnused}/bin/sed -ri 's/^(export PATH=.*)"$/\1:$PATH"/' $out/share/rcfile
      '';

  workerPackage = pkgs.runCommand "fifoci-buildbot-worker" { } ''
    mkdir $out
    ${pkgs.python3Packages.buildbot-worker}/bin/buildbot-worker \
        create-worker \
        --relocatable \
        --force \
        $out ${masterAddr} ${machineName} ${workerPassword}
    echo "Pierre Bourdon <delroth@dolphin-emu.org>" > $out/info/admin
    cat >$out/info/host <<EOF
    ${cfg.info}
    EOF
  '';

  fifociPython = pkgs.python3.withPackages (p: [ p.buildbot-worker ]);

  fifociEnvPackages = with pkgs; [
    bash
    ccache
    ffmpeg
    fifociPython
    git
    imagemagick
    ninja
    poetry
  ];
in
{
  options.my.roles.fifoci-worker = {
    enable = lib.mkEnableOption "FifoCI worker";

    info = lib.mkOption {
      type = lib.types.str;
      default = "NixOS FifoCI worker";
      description = ''
        Information about the machine running the FifoCI worker.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.opengl.enable = true;

    users.users.fifoci = {
      group = "fifoci";
      extraGroups = [ "video" ];
      isSystemUser = true;
      home = homeDir;
      createHome = true;
      shell = fifociShell;
      packages = fifociEnvPackages;
    };
    users.groups.fifoci = { };

    systemd.services.fifoci-buildbot-worker = {
      description = "FifoCI Buildbot Worker";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = fifociEnvPackages;
      environment.PYTHONPATH = "${fifociPython}/${fifociPython.sitePackages}";

      preStart = ''
        mkdir -p ${workerDir}
        ${pkgs.rsync}/bin/rsync -a ${workerPackage}/ ${workerDir}/
        chmod u+w ${workerDir}

        mkdir -p dff

        if ! [ -d fifoci ]; then
          git clone https://github.com/dolphin-emu/fifoci
        fi

        # Clean up build directories since cmake can't figure out paths might
        # have changes when a new system is pushed.
        for d in ${workerDir}/*; do
          [ -d "$d/build" ] && rm -rf $d || true
        done
      '';

      serviceConfig = {
        Type = "simple";
        User = "fifoci";
        Group = "nogroup";
        WorkingDirectory = "${homeDir}";
        ExecStart = "${fifociShell}/bin/fifoci-shell -c 'exec ${pkgs.python3Packages.twisted}/bin/twistd --nodaemon --pidfile= --logfile=- --python ${workerDir}/buildbot.tac'";
        Restart = "always";
        RestartSec = "10";
        Nice = 10;
      };
    };
  };
}
