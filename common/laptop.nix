{ config, ... }:

{
  networking.wireless.enable = true;

  services.tlp.enable = true;
  services.upower.enable = true;

  programs.mosh.enable = true;

  # For better power management support.
  boot.extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
  boot.kernelModules = [ "acpi_call" ];
}
