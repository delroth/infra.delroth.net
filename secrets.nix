let
  pkgs = import <nixpkgs> {};
  canaryHashDerivation = pkgs.runCommand "secrets-canary-hash" {} ''
    sha256sum "${./secrets/canary}" | cut -d ' ' -f 1 | tr -d "\n" > $out
  '';
  canaryHash = builtins.readFile canaryHashDerivation;
  expectedHash = "27a6153adee6291f22bd145f29a5596cef0e87abbc87762576204bc4c8a1cf93";
in
  if canaryHash != expectedHash then abort "Secrets are not readable. Have you run `git-crypt unlock`?"
  else {
    backup = {
      location = builtins.readFile ./secrets/backup-location;
      pass = import ./secrets/backup-pass.nix;
      sshHostPub = ./secrets/backup-ssh-host-pub;
      sshKey = ./secrets/backup-ssh-key;
    };
    distbuild = {
      ssh-public = builtins.readFile ./secrets/distbuild-ssh-pub;
      ssh-private = builtins.readFile ./secrets/distbuild-ssh-priv;
    };
    grafanaSecretKey = builtins.readFile ./secrets/grafana-secret-key;
    matrix = import ./secrets/matrix.nix;
    nodeMetricsKey = builtins.readFile ./secrets/node-metrics-key;
    randstructSeed = builtins.readFile ./secrets/randstruct-seed;
    sso = {
      users = import ./secrets/sso-users.nix;
      groups = import ./secrets/sso-groups.nix;
      key = builtins.readFile ./secrets/sso-key;
    };
    wireguard = {
      clients = import ./secrets/wireguard-clients.nix;
      privateKeys = import ./secrets/wireguard-keys.nix;
    };
    wirelessNetworks = import ./secrets/wireless-networks.nix;
  }
