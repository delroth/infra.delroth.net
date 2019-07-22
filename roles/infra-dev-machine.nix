{ config, lib, nodes, pkgs, ... }:

let
  cfg = config.my.roles.infra-dev-machine;
  my = import ../.;

  distbuildPrivKeyEtcPath = "nix/distbuild-ssh.priv";
in {
  options.my.roles.infra-dev-machine = with lib; {
    enable = mkEnableOption "Infra dev machine";

    extraBuilders = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = ''
        Extra builders to configure outside of the infra.delroth.net
        deployment. The distbuild ssh key is automatically set.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nix = {
      distributedBuilds = true;
      extraOptions = ''
        builders-use-substitutes = true
      '';

      buildMachines =
        let
          builderNodes =
            lib.flip builtins.filter (builtins.attrValues nodes) (node:
              (lib.hasAttrByPath [ "my" "roles" "nix-builder" ] node.config) &&
              node.config.my.roles.nix-builder.enable
            );

          extraNodes = lib.flip builtins.map cfg.extraBuilders (node: {
            sshKey = "/etc/${distbuildPrivKeyEtcPath}";
          } // node);
        in
          lib.flip builtins.map builderNodes (node: {
            hostName = node.config.networking.hostName;
            sshUser = node.config.my.roles.nix-builder.user;
            sshKey = "/etc/${distbuildPrivKeyEtcPath}";
            system = node.config.nixpkgs.localSystem.system;
            maxJobs = node.config.my.roles.nix-builder.maxJobs;
            speedFactor = node.config.my.roles.nix-builder.speedFactor;
            supportedFeatures =
              node.config.my.roles.nix-builder.supportedFeatures;
          }) ++ extraNodes;
    };

    # To work around ssh private key permissions issues, copy the private key
    # out of the nix store to a system path.
    environment.etc."${distbuildPrivKeyEtcPath}" = {
      text = my.secrets.distbuild.ssh-private;
      mode = "0400";
      uid = 0;
      gid = 0;
    };

    # Morph 1.3.1 has a few blocking issues that require patching.
    nixpkgs.overlays = [(self: super: {
      morph = super.morph.overrideAttrs (old: {
        patches = (if old?patches then old.patches else []) ++ [
          (pkgs.fetchurl {
            url = "https://github.com/delroth/morph/commit/949c3eaa50805921c77381a4e248c1f2db1be449.patch";
            sha256 = "0md4mx8fdp8qcv34py3gq1yckp7pf6418vm4ixzi5fajx2xa3vhk";
          })
        ];

        # Assets get bundled before patching in nixpkgs derivation. Fix that.
        prePatch = "";
        postPatch = old.prePatch;
      });
    })];

    environment.systemPackages = with pkgs; [
      diffoscope qemu morph nix-review
    ];
  };
}
