{ config, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/profiles/hardened.nix>
  ];

  # User namespaces are required for sandboxing. Better than nothing imo.
  security.allowUserNamespaces = true;

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;
}
