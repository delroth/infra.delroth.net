{
  ircClient = import ./irc-client.nix;
  matrixSynapse = import ./matrix-synapse.nix;
  syncthingRelay = import ./syncthing-relay.nix;
  torRelay = import ./tor-relay.nix;
  wireguardServer = import ./wireguard-server.nix;
}
