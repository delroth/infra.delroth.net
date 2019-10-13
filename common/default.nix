# Module definitions for common infrastructure layer.
{
  imports = [
     ./backup.nix
     ./filesystem.nix
     ./graphical.nix
     ./laptop.nix
     ./locale.nix
     ./monitoring.nix
     ./networking.nix
     ./nginx.nix
     ./nix.nix
     ./remote-access.nix
     ./scheduling.nix
     ./security.nix
     ./stateless.nix
     ./users.nix
  ];
}
