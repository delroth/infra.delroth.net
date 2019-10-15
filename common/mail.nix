{ config, machineName, secrets, ... }:

{
  # nullmailer needs patching to function under scudo.
  nixpkgs.overlays = [(self: super: {
    nullmailer = super.nullmailer.overrideAttrs (old: {
      patches = [
        (self.fetchurl {
          url = "https://github.com/delroth/nullmailer/commit/834e2eb6b7eac2648fc371c432a46e98d5966bb4.patch";
          sha256 = "0z8jwfc0qa4nf8am06xlvff4xphra5chan37g9s4mlra78s1gwm7";
        })
      ];
    });
  })];

  services.nullmailer = {
    enable = true;
    config = {
      adminaddr = "root@delroth.net";
      allmailfrom = "${machineName}@${machineName}.delroth.net";
      defaultdomain = "delroth.net";
      defaulthost = machineName;
      me = config.networking.hostName;
      remotes = "chaos.delroth.net smtp --port=25 --starttls --user=${secrets.email.smtp-user} --pass=${secrets.email.smtp-password}";
    };
  };
}
