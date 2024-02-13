{
  config,
  lib,
  nodes,
  pkgs,
  secrets,
  ...
}:

let
  cfg = config.my.roles.infra-dev-machine;

  distbuildPrivKeyEtcPath = "nix/distbuild-ssh.priv";
in
{
  options.my.roles.infra-dev-machine = with lib; {
    enable = mkEnableOption "Infra dev machine";

    extraBuilders = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
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
        allowed-uris = https://github.com/ github:NixOS/
      '';

      buildMachines =
        let
          builderNodes = lib.flip builtins.filter (builtins.attrValues nodes) (
            node:
            (lib.hasAttrByPath
              [
                "my"
                "roles"
                "nix-builder"
              ]
              node.config
            )
            && node.config.my.roles.nix-builder.enable
          );

          extraNodes = lib.flip builtins.map cfg.extraBuilders (
            node: { sshKey = "/etc/${distbuildPrivKeyEtcPath}"; } // node
          );
        in
        lib.flip builtins.map builderNodes (
          node: {
            hostName = "${node.config.my.networking.fqdn}";
            sshUser = node.config.my.roles.nix-builder.user;
            sshKey = "/etc/${distbuildPrivKeyEtcPath}";
            protocol = "ssh-ng";
            systems = node.config.my.roles.nix-builder.systems;
            maxJobs = node.config.my.roles.nix-builder.maxJobs;
            speedFactor = node.config.my.roles.nix-builder.speedFactor;
            supportedFeatures = node.config.my.roles.nix-builder.supportedFeatures;
          }
        )
        ++ extraNodes;
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
      colmena
      diffoscope
      qemu
      nixpkgs-review
    ];
  };
}
