{ config, lib, pkgs, ... }:

let
  cfg = config.my.roles.archiveteam-warrior;
in {
  options.my.roles.archiveteam-warrior.enable = lib.mkEnableOption "ArchiveTeam Warrior";

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.backend = "podman";

    virtualisation.oci-containers.containers.archiveteam-warrior = {
      image = "atdr.meo.ws/archiveteam/warrior-dockerfile";
      ports = ["127.0.0.1:8001:8001"];
      cmd = [
        "--concurrent=5"
        "delroth"
      ];
    };
  };
}
