{ config, lib, pkgs, secrets, ... }:

let
  cfg = config.my.roles.fifoci-worker;

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
  in pkgs.runCommand "fifoci-shell" {} ''
    mkdir -p $out/bin $out/share

    cat > $out/bin/fifoci-shell <<EOF
    #! /bin/sh
    exec ${pkgs.bashInteractive}/bin/bash --rcfile $out/share/rcfile "\$@"
    EOF
    chmod +x $out/bin/fifoci-shell

    cat > $out/share/rcfile <<EOF
    export NIX_BUILD_TOP="/tmp"
    export NIX_STORE="/nix/store"

    ${deps}
    out="/tmp"

    old_path="\$PATH"
    source ${pkgs.stdenv}/setup
    set +e
    PATH="\$PATH:\$old_path"; unset old_path
    EOF
  '';

  fifociEnvPackages = (with pkgs; [ ccache git ninja ]) ++ [ fifociShell ];
in {
  options.my.roles.fifoci-worker.enable = lib.mkEnableOption "FifoCI worker";

  config = lib.mkIf cfg.enable {
    users.users.fifoci = {
      isSystemUser = true;
      useDefaultShell = true;
      home = "/srv/fifoci-worker";
      createHome = true;
      packages = fifociEnvPackages;
    };
  };
}
