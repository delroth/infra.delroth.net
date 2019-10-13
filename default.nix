# Common libraries for *.delroth.net. Passed to NixOS modules as "my".
rec {
  common = import ./common;
  pkgs = import ./pkgs;
  roles = import ./roles;
  secrets = import ./secrets.nix;
  services = import ./services;

  modules = {
    imports = [
      common
      roles
      services
    ];
  };
}
