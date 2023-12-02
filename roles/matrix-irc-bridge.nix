{config, lib, ...}:

let
  cfg = config.my.roles.matrix-irc-bridge;
in
{
  options.my.roles.matrix-irc-bridge = {
    enable = lib.mkEnableOption "Matrix IRC Bridge";
  };

  config = lib.mkIf cfg.enable {
    services.heisenbridge = {
      enable = true;
      identd.enable = true;

      homeserver = "https://matrix.delroth.net";
      owner = "@delroth:delroth.net";
      registrationUrl = "https://matrix-irc.delroth.net";
    };

    # TODO: Make work in cases where this isn't on the same machine.
    services.matrix-synapse.settings.app_service_config_files = [
      "/var/lib/heisenbridge/registration.yml"
    ];

    networking.firewall.allowedTCPPorts = [config.services.heisenbridge.identd.port];

    services.nginx = {
      enable = true;

      virtualHosts."matrix-irc.delroth.net" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.services.heisenbridge.port}";
      };
    };
  };
}
