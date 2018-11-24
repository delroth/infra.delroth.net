{ ... }:

rec {
  users.users.delroth = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII3tjB4KYDok3KlWxdBp/yEmqhhmybd+w0VO4xUwLKKV"
      "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAm1Fp4fengE7aO0SOdvb+3pCYEB71UDEvb8hN+xzGGeSJQ++5nvxXf320WT8+WYJ8ToPA6uLaEkX55cYlILwQYVlnztjqrfS8sOheNj+x8iOkoQESz0SEtmi206k1u3Ul8bAP+Gl3QTXju3RXWy2aq7En4kFfiNoHgFGdZ7hroPDD+KF53ZCrwzEQiRyhVxsrhSyn0+hBl7L6bWJMslcRDS7uwbxeThlxPodu5ARlbTPuE5h2gvLN6vJQ5UIscr5VvV55PQwxa6qKX5Yqtxw+3fiAmJZjyp/RXPK8gABkSmC0Sso9ewpss8BLGmPw8ASXg3WL94BeeipzE/QZHbH2AQ=="
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMj+Uu24FJNa6WSW7OdlIvsRxLxaQ+TZYeKTpD+rh0VF0VwP0CRWlMW/v3PvpblcGoVGpBwjHUyWEqSWNwSr1/s="
    ];
  };

  users.users.root.openssh.authorizedKeys.keys =
    users.users.delroth.openssh.authorizedKeys.keys;
}