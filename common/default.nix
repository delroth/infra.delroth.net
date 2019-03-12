# Module definitions for common infrastructure layer.
rec {
  backup = import ./backup.nix;
  filesystem = import ./filesystem.nix;
  graphical = import ./graphical.nix;
  laptop = import ./laptop.nix;
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
      filesystem
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

  laptopBase = { ... }: {
    imports = [
      backup
      filesystem
      graphical
      laptop
      locale
      networking
      nix
      remoteAccess
      security
      stateless
      users
    ];
  };
}
