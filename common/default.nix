# Module definitions for common infrastructure layer.
rec {
  backup = import ./backup.nix;
  locale = import ./locale.nix;
  monitoring = import ./monitoring.nix;
  networking = import ./networking.nix;
  nix = import ./nix.nix;
  remoteAccess = import ./remote-access.nix;
  security = import ./security.nix;
  stateless = import ./stateless.nix;
  users = import ./users.nix;

  # "Base layer" definitions for convenience.
  serverBase = { ... }: {
    imports = [
      backup
      locale
      monitoring
      networking
      nix
      remoteAccess
      security
      stateless
      users
    ];
  };
}
