{ config, pkgs, ... }:

{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "delroth";
    group = "users";
    dataDir = "/home/delroth/.syncthing";
  };
}
