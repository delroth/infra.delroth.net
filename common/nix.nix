{ machineName, ... }:

{
  nix.autoOptimiseStore = true;
  documentation = {
    doc.enable = false;
    info.enable = false;
    man.enable = true;
    nixos.enable = false;
  };
  nix.gc.automatic = true;
  nix.trustedUsers = [ "root" "@wheel" ];

  # Support local nixos-rebuild for development/testing.
  nix.nixPath = [
    "nixos-config=/etc/nixos/machines/${machineName}"
  ];
}
