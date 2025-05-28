{
  config,
  lib,
  nodes,
  secrets,
  ...
}:
let
  cfg = config.my.roles.homenet-gateway;

  homenetNodes = lib.mapAttrs (name: node: node.config) (
    lib.flip lib.filterAttrs nodes (
      name: node:
      (lib.hasAttrByPath
        [
          "my"
          "homenet"
        ]
        node.config
      )
      && node.config.my.homenet.enable
    )
  );

  httpsVhosts = lib.flatten (
    lib.mapAttrsToList (name: node:
      lib.mapAttrsToList (vName: vCfg:
        # TODO: Filter to only stuff listening on 443?
        # TODO: Detect stuff like wildcards (e.g. s3).
        {
          hostname = vName;
          ipv6 = "${cfg.homenetIp6Prefix}0::${node.my.homenet.ipSuffix}";
        }
      ) node.services.nginx.virtualHosts
    ) homenetNodes
  );
in
{
  config = lib.mkIf cfg.enable {
    services.sniproxy = {
      enable = true;
      config = ''
        listener 127.0.0.1:4443 {
          protocol tls
          table HttpsVhosts

          fallback 127.0.0.1:443
        }

        table HttpsVhosts {
          ${builtins.concatStringsSep "\n" (
            map (e: "${e.hostname} [${e.ipv6}]:443") httpsVhosts
          )}
        }
      '';
    };

    # Magic redirection :443 -> :4443 happens in firewall.nix.
    networking.firewall = {
      allowedTCPPorts = [ 443 4443 ];
      allowedUDPPorts = [ 443 4443 ];
    };

    # Allow routing to lo.
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.route_localnet" = true;
    };
  };
}
