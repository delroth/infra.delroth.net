# Module definitions for common infrastructure layer.
rec {
  locale = import ./locale.nix;
  monitoring = import ./monitoring.nix;
  networking = import ./networking.nix;
  nix = import ./nix.nix;
  remoteAccess = import ./remote-access.nix;
  security = import ./security.nix;
  users = import ./users.nix;

  # "Base layer" definitions for convenience.
  serverBase = { ... }: {
    imports = [
      locale
      monitoring
      networking
      nix
      remoteAccess
      security
      users
    ];
  };
}
