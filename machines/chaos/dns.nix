{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:

let
  secondaryDnsServers = [
    "69.65.50.192" # ns2.afraid.org
    "204.42.254.5" # puck.nether.net
  ];
in
{
  services.bind = {
    enable = true;

    cacheNetworks = [
      "127.0.0.0/24"
      "::1/128"
    ];
    forwarders = [ "127.0.0.53 port 53" ];

    extraOptions = ''
      notify yes;
    '';

    extraConfig = ''
      ${lib.concatStrings (lib.mapAttrsToList (name: attrs: ''
        key "${name}." {
          algorithm ${attrs.algo};
          secret "${attrs.secret}";
        };
      '') secrets.dnsupdate)}

      dnssec-policy "delroth-net" {
        keys {
          ksk key-directory lifetime unlimited algorithm 13;
          zsk key-directory lifetime unlimited algorithm 13;
        };
        nsec3param;
      };
    '';

    zones = [
      {
        master = true;
        name = "delroth.net";
        file = "/srv/dns/delroth.net.zone";
        slaves = secondaryDnsServers;
        extraConfig = ''
          key-directory "/etc/bind/keys";
          dnssec-policy "delroth-net";
          inline-signing yes;

          update-policy {
            grant s3-role. name _acme-challenge.delroth.net. txt;
            grant s3-role. name _acme-challenge.s3.delroth.net. txt;
            grant s3-role. name _acme-challenge.s3-web.delroth.net. txt;
          };
        '';
      }
      {
        master = true;
        name = "6.2.4.6.8.6.1.0.2.0.a.2.ip6.arpa";
        file = "/srv/dns/6.2.4.6.8.6.1.0.2.0.a.2.ip6.arpa.zone";
        slaves = secondaryDnsServers;
      }
    ];
  };

  environment.etc =
    lib.mapAttrs'
      (filename: contents: {
        name = "bind/keys/${filename}";
        value = {
          user = "named";
          group = "root";
          mode = "0400";
          text = contents;
        };
      })
      secrets.dnssec;

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
