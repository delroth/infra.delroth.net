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
    grafanaSecretKey = builtins.readFile ./secrets/grafana-secret-key;
    nodeMetricsKey = builtins.readFile ./secrets/node-metrics-key;
    sso = {
      users = import ./secrets/sso-users.nix;
      groups = import ./secrets/sso-groups.nix;
      key = builtins.readFile ./secrets/sso-key;
    };
  }
