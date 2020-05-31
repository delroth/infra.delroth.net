{ config, lib, pkgs, secrets, ... }:

let
  sasl-db = pkgs.runCommand "sasl.db" {} ''
    echo "${secrets.email.smtp-password}" | \
      ${pkgs.cyrus_sasl}/bin/saslpasswd2 \
        -f $out \
        -u ${config.my.networking.fqdn} \
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
  options.my.roles.smtp-server = {
    enable = lib.mkEnableOption "SMTP server";
  };

  config = lib.mkIf config.my.roles.smtp-server.enable {
    services.postfix = {
      enable = true;
      enableSubmission = true;

      sslCert = "/var/lib/acme/${config.my.networking.fqdn}/fullchain.pem";
      sslKey = "/var/lib/acme/${config.my.networking.fqdn}/key.pem";

      recipientDelimiter = "+";
      rootAlias = "delroth";

      config = {
        cyrus_sasl_config_path = "${sasl-conf-dir}";
        smtpd_sasl_auth_enable = true;
        smtpd_tls_auth_only = true;
      };
      destination = [
        config.my.networking.fqdn
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
        acme: delroth
        tor: delroth
        delroth: delroth@gmail.com
        devnull: /dev/null

        # epita.eu entries
        faq: antoine.pietri@epita.fr, delroth
        mastercorp: mastercorp@ycc.fr, delroth
        map: mastercorp@ycc.fr
      '';
    };

    networking.firewall.allowedTCPPorts = [config.services.postfix.relayPort];

    security.acme.certs = {
      "${config.my.networking.fqdn}".postRun = ''
        systemctl reload postfix
      '';
    };
  };
}
