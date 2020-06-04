{ ... }:

let
  my = import ../..;
in {
  imports = [
    ./hardware.nix

    my.modules
  ];

  my.roles = {
  };

  # Remove a few non-essentials to avoid having to build LLVM and Spidermonkey.
  security.apparmor.enable = false;
  security.polkit.enable = false;
  services.udisks2.enable = false;
}
