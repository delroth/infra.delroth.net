let
  pkgs = import <nixpkgs> {};
  canaryHash = builtins.hashFile "sha256" ./secrets/canary;
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
    bgp = import ./secrets/bgp.nix;
    buildbot-worker = import ./secrets/buildbot-worker.nix;
    distbuild = {
      ssh-public = builtins.readFile ./secrets/distbuild-ssh-pub;
      ssh-private = builtins.readFile ./secrets/distbuild-ssh-priv;
    };
    dnssec = pkgs.lib.genAttrs
      (builtins.attrNames (builtins.readDir ./secrets/dnssec))
      (f: builtins.readFile (./secrets/dnssec + "/${f}"));
    email = import ./secrets/email.nix;
    flexget-config = import ./secrets/flexget-config.nix;
    glome = import ./secrets/glome.nix;
    grafanaSecretKey = builtins.readFile ./secrets/grafana-secret-key;
    homenet = import ./secrets/homenet.nix;
    iot = import ./secrets/iot.nix;
    matrix = import ./secrets/matrix.nix;
    nasPassword = builtins.readFile ./secrets/nas-password;
    nodeMetricsKey = builtins.readFile ./secrets/node-metrics-key;
    pkgs = import ./secrets/pkgs;
    randstructSeed = builtins.readFile ./secrets/randstruct-seed;
    repologyNotifierGhToken = builtins.readFile ./secrets/repology-notifier-gh-token;
    roles = import ./secrets/roles;
    seedbox-vpn = import ./secrets/seedbox-vpn.nix;
    shadowHash = builtins.readFile ./secrets/shadow-hash;
    sso = {
      users = import ./secrets/sso-users.nix;
      groups = import ./secrets/sso-groups.nix;
      key = builtins.readFile ./secrets/sso-key;
    };
    syncthing = import ./secrets/syncthing.nix;
    transmissionPassword = builtins.readFile ./secrets/transmission-password;
    wireguard = {
      cfg = import ./secrets/wireguard.nix;
      peers = import ./secrets/wireguard-peers.nix;
      privateKeys = import ./secrets/wireguard-keys.nix;
    };
  }
