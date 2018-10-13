{ config, pkgs, ... }:

{
  services.postfix = {
    enable = true;
    enableSubmission = true;

    sslCert = "/var/lib/acme/${config.networking.hostName}/fullchain.pem";
    sslKey = "/var/lib/acme/${config.networking.hostName}/key.pem";

    recipientDelimiter = "+";
    rootAlias = "delroth";

    destination = [
      config.networking.hostName
      "localhost"
      "delroth.net"
      "epita.eu"
    ];
    extraAliases = ''
      MAILER-DAEMON: postmaster
      operator: postmaster
      abuse: postmaster

      me: delroth
      delroth: delroth@gmail.com
      devnull: /dev/null

      # epita.eu entries
      faq: antoine.pietri@epita.fr, delroth
      mastercorp: mastercorp@ycc.fr, delroth
      map: mastercorp@ycc.fr
    '';
  };

  networking.firewall.allowedTCPPorts = [config.services.postfix.relayPort];

  security.acme.certs."${config.networking.hostName}".postRun = ''
    systemctl reload postfix
  '';
}
