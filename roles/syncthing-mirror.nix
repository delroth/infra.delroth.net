{ config, lib, machineName, pkgs, ... }:

let
  cfg = config.my.roles.syncthing-mirror;
  my = import ../.;

  devices = builtins.mapAttrs (name: info: {
    inherit name;
    id = info.id;
    introducer = true;
  }) my.secrets.syncthing;
in {
  options.my.roles.syncthing-mirror.enable =
    lib.mkEnableOption "Syncthing mirror role";

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
      user = "delroth";
      group = "users";
      dataDir = "/home/delroth/.syncthing";

      declarative = {
        cert = "${pkgs.writeText "syncthing-cert.pem" my.secrets.syncthing."${machineName}".cert}";
        key = "${pkgs.writeText "syncthing-key.pem" my.secrets.syncthing."${machineName}".key}";

        inherit devices;

        # TODO(delroth): Make folders configuration declarative when versioning
        # schemes are supported.
        overrideFolders = false;
      };
    };
  };
}
