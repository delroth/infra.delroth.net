{ pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/profiles/hardened.nix>
  ];

  # User namespaces are required for sandboxing. Better than nothing imo.
  security.allowUserNamespaces = true;

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
}
