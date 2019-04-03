{ config, ... }:

let
  my = import ../.;
in {
  networking.wireless.enable = true;

  services.tlp.enable = true;
  services.upower.enable = true;

  programs.mosh.enable = true;

  # For better power management support.
  boot.extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
  boot.kernelModules = [ "acpi_call" ];

  # Set a password for the main login user.
  users.users.delroth.hashedPassword = my.secrets.shadowHash;
}
