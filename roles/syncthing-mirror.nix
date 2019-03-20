{ config, lib, ... }:

let
  cfg = config.my.roles.syncthing-mirror;
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
    };
  };
}
