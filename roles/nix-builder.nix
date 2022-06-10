{ config, lib, pkgs, secrets, ... }:

let
  cfg = config.my.roles.nix-builder;
in {
  options.my.roles.nix-builder = {
    enable = lib.mkEnableOption "Remote Nix builder";

    user = lib.mkOption {
      type = lib.types.str;
      default = "nix-remote-builder";
      description = ''
        Name of the user to create for remote nix builds on this machine.
      '';
    };

    maxJobs = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = ''
        Maximum number of builds to run at once on this machine.
      '';
    };

    speedFactor = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = ''
        Number that represents how fast this machine is, for scheduling
        priorities.
      '';
    };

    supportedFeatures = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "big-parallel" "kvm" "nixos-test" ];
      description = ''
        Supported features for package builds on this machine.
      '';
    };

    systems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ config.nixpkgs.localSystem.system ];
      description = ''
        System types that this builder can build for. Example: x86_64-linux,
        aarch64-linux, etc.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users."${cfg.user}" = {
      isSystemUser = true;
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [ secrets.distbuild.ssh-public ];
      group = cfg.user;
    };
    users.groups."${cfg.user}" = {};

    nix.settings.trusted-users = [ cfg.user ];
  };
}
