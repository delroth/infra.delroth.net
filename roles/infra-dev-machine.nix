{ config, lib, nodes, pkgs, secrets, ... }:

let
  cfg = config.my.roles.infra-dev-machine;

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

          managedNodes = lib.flip builtins.map builderNodes (node: {
            hostName = node.config.networking.hostName;
            sshUser = node.config.my.roles.nix-builder.user;
            sshKey = "/etc/${distbuildPrivKeyEtcPath}";
            system = node.config.nixpkgs.localSystem.system;
            maxJobs = node.config.my.roles.nix-builder.maxJobs;
            speedFactor = node.config.my.roles.nix-builder.speedFactor;
            supportedFeatures =
              node.config.my.roles.nix-builder.supportedFeatures;
          });

          managedNodesArm8 = lib.flip builtins.map managedNodes
            (node: node // { system = "aarch64-linux"; });

          extraNodes = lib.flip builtins.map cfg.extraBuilders (node: {
            sshKey = "/etc/${distbuildPrivKeyEtcPath}";
          } // node);
        in
          managedNodes ++ managedNodesArm8 ++ extraNodes;
    };

    # To work around ssh private key permissions issues, copy the private key
    # out of the nix store to a system path.
    environment.etc."${distbuildPrivKeyEtcPath}" = {
      text = secrets.distbuild.ssh-private;
      mode = "0400";
      uid = 0;
      gid = 0;
    };

    environment.systemPackages = with pkgs; [
      diffoscope qemu morph nix-review
    ];
  };
}
