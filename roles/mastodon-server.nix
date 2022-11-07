{ config, lib, pkgs, secrets, ... }:

let
  cfg = config.my.roles.mastodon-server;
in {
  options.my.roles.mastodon-server = {
    enable = lib.mkEnableOption "Mastodon server";
  };

  config = lib.mkIf cfg.enable {
    services.postgresql.enable = true;

    services.mastodon = {
      enable = true;
      localDomain = "delroth.net";

      smtp.host = "chaos.delroth.net";
      smtp.fromAddress = "mastodon@delroth.net";
      smtp.authenticate = true;
      smtp.user = secrets.email.smtp-user;
      smtp.passwordFile = "${pkgs.runCommand "smtp-password" {} ''
        echo "${secrets.email.smtp-password}" > $out
      ''}";

      extraConfig.WEB_DOMAIN = "mastodon.delroth.net";
      extraConfig.SINGLE_USER_MODE = "true";
    };

    services.nginx = {
      enable = true;

      virtualHosts."mastodon.delroth.net" = {
        root = "${config.services.mastodon.package}/public/";
        forceSSL = true;
        enableACME = true;

        locations."/system/".alias = "/var/lib/mastodon/public-system/";
        locations."/".tryFiles = "$uri @proxy";

        locations."@proxy".proxyPass = "http://unix:/run/mastodon-web/web.socket";
        locations."@proxy".proxyWebsockets = true;

        locations."/api/v1/streaming/".proxyPass = "http://unix:/run/mastodon-streaming/streaming.socket";
        locations."/api/v1/streaming/".proxyWebsockets = true;
      };
    };

    users.groups.mastodon.members = [ config.services.nginx.user ];
  };
}