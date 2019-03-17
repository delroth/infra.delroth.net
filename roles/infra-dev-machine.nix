{ config, lib, nodes, pkgs, ... }:

let
  cfg = config.my.roles.infra-dev-machine;
  my = import ../.;

  distbuildPrivKeyEtcPath = "nix/distbuild-ssh.priv";
in {
  options.my.roles.infra-dev-machine = {
    enable = lib.mkEnableOption "Infra dev machine";
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
          });
    };

    # To work around ssh private key permissions issues, copy the private key
    # out of the nix store to a system path.
    environment.etc."${distbuildPrivKeyEtcPath}" = {
      text = my.secrets.distbuild.ssh-private;
      mode = "0400";
      uid = 0;
      gid = 0;
    };

    environment.systemPackages = [ pkgs.nixops ];
  };
}
