{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:

let
  cfg = config.my.roles.mastodon-server;
in
{
  options.my.roles.mastodon-server = {
    enable = lib.mkEnableOption "Mastodon server";
  };

  config = lib.mkIf cfg.enable {
    services.postgresql.enable = true;
    services.elasticsearch.enable = true;

    services.mastodon = {
      enable = true;
      localDomain = "delroth.net";

      streamingProcesses = 4;

      package = pkgs.mastodon.overrideAttrs (final: prev: {
        postPatch = (prev.postPatch or "") + ''
          substituteInPlace app/models/concerns/attachmentable.rb \
              --replace-fail 33_177_600 60_000_000
        '';
      });

      smtp.host = "chaos.delroth.net";
      smtp.fromAddress = "mastodon@delroth.net";
      smtp.authenticate = true;
      smtp.user = secrets.email.smtp-user;
      smtp.passwordFile = "${pkgs.runCommand "smtp-password" { } ''
        echo "${secrets.email.smtp-password}" > $out
      ''}";

      elasticsearch.host = "127.0.0.1";

      extraConfig.AUTHORIZED_FETCH = "true";
      extraConfig.WEB_DOMAIN = "mastodon.delroth.net";
      extraConfig.SINGLE_USER_MODE = "true";
    };

    services.nginx = {
      enable = true;

      upstreams.mastodon-streaming = {
        extraConfig = ''
          least_conn;
        '';

        servers = builtins.listToAttrs (map (i: {
          name = "unix:/run/mastodon-streaming/streaming-${i}.socket";
          value = {};
        }) (lib.range 1 config.services.mastodon.streamingProcesses));
      };

      virtualHosts."mastodon.delroth.net" = {
        root = "${config.services.mastodon.package}/public/";
        forceSSL = true;
        enableACME = true;

        locations."/system/".alias = "/var/lib/mastodon/public-system/";
        locations."/".tryFiles = "$uri @proxy";

        locations."@proxy".proxyPass = "http://unix:/run/mastodon-web/web.socket";
        locations."@proxy".proxyWebsockets = true;

        locations."/api/v1/streaming/".proxyPass = "http://mastodon-streaming";
        locations."/api/v1/streaming/".proxyWebsockets = true;

        extraConfig = ''
          client_max_body_size 100m;
        '';
      };
    };

    users.groups.mastodon.members = [ config.services.nginx.user ];
  };
}
