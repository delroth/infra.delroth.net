{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:

let
  cfg = config.my.roles.repology-notifier;

  settings = {
    maintainerEmail = "delroth@gmail.com";
    repository = "nix_unstable";
    githubRepo = "delroth/maintained-packages";
    githubToken = secrets.repologyNotifierGhToken;
  };
in
{
  options.my.roles.repology-notifier.enable = lib.mkEnableOption "Repology notifier";

  config = lib.mkIf cfg.enable {
    systemd.services.repology-notifier = {
      description = "Repology outdated notifier";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        ExecStart = ''
          ${pkgs.repology-notifier}/bin/repology-outdated-notify.py \
              -m ${settings.maintainerEmail} \
              -r ${settings.repository} \
              -g ${settings.githubRepo} \
              -t ${settings.githubToken}
        '';
      };
    };
  };
}
