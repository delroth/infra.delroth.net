{ config, lib, pkgs, secrets, ... }:

let
  x86 = pkgs.stdenv.isx86_64;
in {
  imports = [
    <nixpkgs/nixos/modules/profiles/hardened.nix>
  ];

  config = lib.mkMerge [{
    # Let's Encrypt related configuration.
    security.acme.acceptTerms = true;
    security.acme.email = "acme@delroth.net";

    # User namespaces are required for sandboxing. Better than nothing imo.
    security.allowUserNamespaces = true;

    # Hyperthreading is not a concern for single-user environments. PTI mostly
    # isn't either.
    security.allowSimultaneousMultithreading = true;
    security.forcePageTableIsolation = false;

    security.sudo.enable = true;
    security.sudo.wheelNeedsPassword =  # Require password if set.
      config.users.users.delroth.hashedPassword != null;

    services.haveged.enable = true;

    # TODO: Once more build capacity has been converted to NixOS, add hostname
    # to the seed as well for more diversity.
    boot.kernel.randstructSeed = "${secrets.randstructSeed}";
  }

  (lib.mkIf x86 {
    # Use the hardened kernel but keep IA32 emulation.
    boot.kernelPackages =
      pkgs.linuxPackagesFor (pkgs.linux_latest_hardened.override {
        features.ia32Emulation = true;
      });
    boot.kernelPatches = [{
      name = "keep-ia32";
      patch = null;
      extraConfig = ''
        IA32_EMULATION y
      '';
    }];

    environment.memoryAllocator.provider = "libc";
  })

  (lib.mkIf (!x86) {
    # TODO: Maybe try switching this once things get more stable. Currently
    # scudo's malloc provider derivation doesn't build on NixOS.
    environment.memoryAllocator.provider = "libc";
  })];
}
