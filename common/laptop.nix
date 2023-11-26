{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:

{
  options = {
    my.laptop.enable = lib.mkEnableOption "Laptop specific configuration";
  };

  config = lib.mkIf config.my.laptop.enable {
    hardware.bluetooth.enable = true;

    networking.networkmanager.enable = true;
    programs.nm-applet.enable = true;

    # Disable systemd-networkd-wait-online since by default all interfaces are
    # managed by NM.
    systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = lib.mkForce [
      ""
      "${pkgs.coreutils}/bin/true"
    ];

    services.tlp.enable = true;
    services.upower.enable = true;

    programs.mosh.enable = true;

    environment.systemPackages = with pkgs; [ brightnessctl ];

    # For better power management support.
    boot.extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
    boot.kernelModules = [ "acpi_call" ];

    # Set groups and a password for the main login user.
    users.users.delroth = {
      hashedPassword = lib.mkForce secrets.shadowHash;
      extraGroups = [ "video" ];
    };

    my.monitoring.roaming = lib.mkDefault true;
    my.stateless.enable = lib.mkDefault false;
  };
}
