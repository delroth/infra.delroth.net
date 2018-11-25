# Common libraries for *.delroth.net. Passed to NixOS modules as "my".
{
  common = import ./common;
  pkgs = import ./pkgs;
  roles = import ./roles;
  secrets = import ./secrets.nix;
  services = import ./services;
}
