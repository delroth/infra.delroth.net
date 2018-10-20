{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nginx.sso;
  pkg = import ../pkgs/nginx-sso.nix;
  configYml = pkgs.writeText "nginx-sso.yml" (builtins.toJSON cfg.configuration);
in {
  options.services.nginx.sso = {
    enable = mkEnableOption "nginx-sso service";

    user = mkOption {
      type = types.str;
      default = "nobody";
      description = ''
        User name under which nginx-sso shall be run.
      '';
    };

    group = mkOption {
      type = types.str;
      default = "nogroup";
      description = ''
        Group name under which nginx-sso shall be run.
      '';
    };

    configuration = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        nginx-sso configuration as Nix attribute set.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.nginx-sso = {
      description = "Nginx SSO Backend";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        ${pkg.bin}/bin/nginx-sso \
          --config ${configYml}
      '';
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        PrivateTmp = "true";
        WorkingDirectory = "/tmp";
      };
    };
  };
}
