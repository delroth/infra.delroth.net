{ config, lib, machineName, pkgs, secrets, ... }:

let
  cfg = config.my.roles.syncthing-mirror;

  devices = builtins.mapAttrs (name: info: {
    inherit name;
    id = info.id;
    introducer = true;
  }) secrets.syncthing;
in {
  options.my.roles.syncthing-mirror = {
    enable = lib.mkEnableOption "Syncthing mirror role";
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
      user = "delroth";
      group = "users";
      dataDir = "/home/delroth/.syncthing";

      declarative = {
        cert = "${pkgs.writeText "syncthing-cert.pem" secrets.syncthing."${machineName}".cert}";
        key = "${pkgs.writeText "syncthing-key.pem" secrets.syncthing."${machineName}".key}";

        inherit devices;

        # TODO(delroth): Make folders configuration declarative when versioning
        # schemes are supported.
        overrideFolders = false;
      };
    };
  };
}
