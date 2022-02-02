{ config, lib, pkgs, ... }:

let
  kernelPackages = import ./kernel.nix { inherit pkgs; };
in {
  imports = [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix> ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "usbhid" "sd_mod" "sdhci_pci" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.blacklistedKernelModules = [ "dvb_usb_rtl28xxu" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/937be0f2-f8d7-424d-883a-10dad3d2ddc3";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/163E-FD2E";
    fsType = "vfat";
  };

  nix.settings.max-jobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  boot.kernelPackages = lib.mkForce kernelPackages;
  boot.extraModulePackages = [
    kernelPackages.intel_nuc_led
  ];
  boot.kernel.sysctl."net.core.bpf_jit_enable" = null;

  # Disable annoying gamer LEDs.
  systemd.services.disable-leds = {
    description = "Disable NUC LEDs";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      echo set_indicator,2,6 > /proc/acpi/nuc_led
      echo set_indicator,3,6 > /proc/acpi/nuc_led
    '';
  };
}
