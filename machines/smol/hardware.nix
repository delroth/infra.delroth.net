{
  config,
  lib,
  pkgs,
  nixpkgs,
  ...
}:

let
  kernelPackages = import ./kernel.nix {
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      crossSystem = config.nixpkgs.localSystem;
    };
  };
in
{
  nixpkgs.localSystem = lib.systems.examples.aarch64-multiplatform;

  boot.kernelPackages = lib.mkForce kernelPackages;
  boot.initrd.includeDefaultModules = false;
  boot.extraModulePackages = [
    kernelPackages.al_eth
    # TODO: stabilize before enabling by default
    # kernelPackages.al_nand
    kernelPackages.al_thermal
  ];
  boot.kernelParams = [
    "console=ttyS0,115200"
    "earlycon"
    "panic=3"
  ];
  boot.kernelModules = [
    "drivetemp" # For drive temperature monitoring.
    "i2c-mux-pca954x" # For SFP+ link management.
  ];

  networking.hostId = "ca504f8f";

  boot.loader.grub.enable = false;

  fileSystems."/" = {
    device = "/dev/disk/by-label/root";
    fsType = "ext4";
    options = [
      "noatime"
      "discard"
    ];
  };

  # Set fans at full speed on startup. Ideally this should be done by a kernel
  # module instead which provides fan PWM control, but that's for later.
  systemd.services.spin-fans = {
    description = "Spin up the fans, full throttle.";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.coreutils}/bin/stty -F /dev/ttyS1 115200
      echo -ne '\x34' > /dev/ttyS1
    '';
  };

  nix.settings.max-jobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
