{ config, lib, machineName, pkgs, secrets, ... }:

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
  fifociShell = let
    dol = pkgs.dolphinEmuMaster;
    inputAttrs = [
      "buildInputs"
      "nativeBuildInputs"
      "propagatedBuildInputs"
      "propagatedNativeBuildInputs"
    ];
    deps = lib.concatMapStringsSep "\n" (attr:
      let
        l = dol."${attr}";
        spaceSeparated = lib.concatMapStringsSep " " (drv: "${drv}") l;
      in
        "${attr}=\"${spaceSeparated}\""
    ) inputAttrs;
  in pkgs.runCommand "fifoci-shell" {
    passthru = {
      shellPath = "/bin/fifoci-shell";
    };
  } ''
    mkdir -p $out/bin $out/share

    cat > $out/bin/fifoci-shell <<EOF
    #! /bin/sh
    rc=$out/share/rcfile
    exec BASH_ENV=$rc ${pkgs.bashInteractive}/bin/bash --rcfile $rc "\$@"
    EOF
    chmod +x $out/bin/fifoci-shell

    # Lifted from the nix-shell implementation.
    cat > $out/share/rcfile <<EOF
    export NIX_BUILD_TOP="/tmp"
    export NIX_STORE="/nix/store"

    ${deps}
    out="/tmp"

    old_path="\$PATH"
    source ${pkgs.stdenv}/setup
    set +e
    export PATH="\$PATH:\$old_path"; unset old_path
    EOF
  '';

  workerPackage = pkgs.runCommand "fifoci-buildbot-worker" {} ''
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

  fifociPython = pkgs.python3.withPackages (p: [
    p.buildbot-worker p.pillow p.requests
  ]);

  fifociEnvPackages = with pkgs; [ ccache fifociPython git ninja ];
in {
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
      isSystemUser = true;
      home = homeDir;
      createHome = true;
      shell = fifociShell;
      packages = fifociEnvPackages;
    };

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

        rm -f python && ln -sf ${fifociPython}/bin/python python
      '';

      serviceConfig = {
        Type = "simple";
        User = "fifoci";
        Group = "nogroup";
        WorkingDirectory = "${homeDir}";
        ExecStart = "${fifociShell}/bin/fifoci-shell -c 'exec ${pkgs.python3Packages.twisted}/bin/twistd --nodaemon --pidfile= --logfile=- --python ${workerDir}/buildbot.tac'";
        Restart = "always";
        RestartSec = "10";
      };
    };
  };
}
