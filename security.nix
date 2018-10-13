{ config, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/profiles/hardened.nix>
  ];

  # User namespaces are required for sandboxing. Better than nothing imo.
  boot.kernel.sysctl."user.max_user_namespaces" = 65535;

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;
}
