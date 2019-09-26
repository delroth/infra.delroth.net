{ config, lib, pkgs, secrets, staging, ... }:

let
  sasl-db = pkgs.runCommand "sasl.db" {} ''
    echo "${secrets.email.smtp-password}" | \
      ${pkgs.cyrus_sasl}/bin/saslpasswd2 \
        -f $out \
        -u ${config.networking.hostName} \
        -c -p \
        ${secrets.email.smtp-user}
  '';
  sasl-conf = pkgs.writeText "sasl-smtpd.conf" ''
    pwcheck_method: auxprop
    auxprop_plugin: sasldb
    mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5 NTLM
    sasldb_path: ${sasl-db}
  '';
  sasl-conf-dir = pkgs.runCommand "sasl-conf.d" {} ''
    mkdir $out
    ln -s ${sasl-conf} $out/smtpd.conf
  '';
in {
  services.postfix = {
    enable = true;
    enableSubmission = true;

    sslCert = lib.mkIf (!staging) "/var/lib/acme/${config.networking.hostName}/fullchain.pem";
    sslKey = lib.mkIf (!staging) "/var/lib/acme/${config.networking.hostName}/key.pem";

    recipientDelimiter = "+";
    rootAlias = "delroth";

    config = {
      cyrus_sasl_config_path = "${sasl-conf-dir}";
      smtpd_sasl_auth_enable = true;
      smtpd_tls_auth_only = true;
    };
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
