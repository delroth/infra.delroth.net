{ config, secrets, ... }:

{
  hardware.bluetooth.enable = true;
  networking.wireless.enable = true;

  services.tlp.enable = true;
  services.upower.enable = true;

  programs.mosh.enable = true;

  # For better power management support.
  boot.extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
  boot.kernelModules = [ "acpi_call" ];

  networking.dhcpcd.extraConfig = ''
    # Skip ARP probing and trust the DHCP server to have given us a valid
    # assignment. Improves time to network availability.
    noarp
  '';

  # Set a password for the main login user.
  users.users.delroth.hashedPassword = secrets.shadowHash;
}
