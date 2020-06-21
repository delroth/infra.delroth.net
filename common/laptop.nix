{ config, lib, pkgs, secrets, ... }:

{
  options = {
    my.laptop.enable = lib.mkEnableOption "Laptop specific configuration";
  };

  config = lib.mkIf config.my.laptop.enable {
    hardware.bluetooth.enable = true;
    networking.wireless.enable = true;

    services.tlp.enable = true;
    services.upower.enable = true;

    programs.mosh.enable = true;

    environment.systemPackages = with pkgs; [ brightnessctl ];

    # For better power management support.
    boot.extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
    boot.kernelModules = [ "acpi_call" ];

    networking.dhcpcd.extraConfig = ''
      # Skip ARP probing and trust the DHCP server to have given us a valid
      # assignment. Improves time to network availability.
      noarp
    '';

    # Set groups and a password for the main login user.
    users.users.delroth = {
      hashedPassword = lib.mkForce secrets.shadowHash;
      extraGroups = [ "video" ];
    };

    my.stateless.enable = lib.mkDefault false;
  };
}
