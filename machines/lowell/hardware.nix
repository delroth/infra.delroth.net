{ lib, pkgs, ... }:

{
  hardware.enableRedistributableFirmware = true;

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.loader.systemd-boot.enable = true;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/9e0a75fd-be40-4b3f-891c-092f4f201725";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."plain" = {
    device = "/dev/disk/by-uuid/592d5b09-2910-44be-abe6-dceac543e726";
    allowDiscards = true;
  };

  services.fstrim.enable = true;

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/E5C0-C972";
      fsType = "vfat";
    };

  nix.settings.max-jobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  services.xserver.xkbOptions = "compose:prsc";

  # Fix S3 sleep support -- don't wake up on XHCI events.
  systemd.services.disable-xhci-wakeup = {
    description = "Disables XHCI wakeup for S3 sleep support.";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if ${pkgs.gnugrep}/bin/grep -q 'XHCI.*enabled' /proc/acpi/wakeup; then
        echo XHCI > /proc/acpi/wakeup
      fi
    '';
  };

  # Battery care: only charge up from 40% to 80%.
  services.tlp.settings = {
    START_CHARGE_THRESH_BAT0 = 40;
    STOP_CHARGE_THRESH_BAT0 = 80;
  };
}
