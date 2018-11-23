{ config, lib, staging, ... }:

{
  services.postfix = {
    enable = true;
    enableSubmission = true;

    sslCert = lib.mkIf (!staging) "/var/lib/acme/${config.networking.hostName}/fullchain.pem";
    sslKey = lib.mkIf (!staging) "/var/lib/acme/${config.networking.hostName}/key.pem";

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
      alerts: postmaster

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

  security.acme.certs = lib.mkIf (!staging) {
    "${config.networking.hostName}".postRun = ''
      systemctl reload postfix
    '';
  };
}
