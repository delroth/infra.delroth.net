# Common libraries for *.delroth.net. Passed to NixOS modules as "my".
{
  common = import ./common;
  machines = import ./machines;
  pkgs = import ./pkgs;
  roles = import ./roles;
  secrets = import ./secrets.nix;
  services = import ./services;
}
