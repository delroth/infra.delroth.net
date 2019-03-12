{ pkgs, ... }:

let
  my = import ../.;
in {
  imports = [
    <nixpkgs/nixos/modules/profiles/hardened.nix>
  ];

  # User namespaces are required for sandboxing. Better than nothing imo.
  security.allowUserNamespaces = true;

  # Hyperthreading is not a concern for single-user environments.
  security.allowSimultaneousMultithreading = true;

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  services.haveged.enable = true;

  # Use the hardened kernel but keep IA32 emulation.
  boot.kernelPackages = pkgs.linuxPackages_latest_hardened;
  boot.kernelPatches = [{
    name = "keep-ia32";
    patch = null;
    extraConfig = ''
      IA32_EMULATION y
    '';
  }];

  # TODO: Once more build capacity has been converted to NixOS, add hostname to
  # the seed as well for more diversity.
  boot.kernel.randstructSeed = "${my.secrets.randstructSeed}";
}
