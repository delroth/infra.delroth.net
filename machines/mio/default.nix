{ ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.networking.externalInterface = "eth0";

  my.roles = {
    nix-builder.enable = true;
  };

  my.homenet = {
    enable = true;
    macAddress = "a2:ad:a4:53:df:74";
    ipSuffix = 13;
  };

  my.roles.nix-builder.speedFactor = 4;
  my.roles.nix-builder.systems = [ "x86_64-linux" "i686-linux" ];
}
