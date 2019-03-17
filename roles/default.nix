{
  infraDevMachine = import ./infra-dev-machine.nix;
  ircClient = import ./irc-client.nix;
  matrixSynapse = import ./matrix-synapse.nix;
  nixBuilder = import ./nix-builder.nix;
  syncthingRelay = import ./syncthing-relay.nix;
  torRelay = import ./tor-relay.nix;
  wireguardServer = import ./wireguard-server.nix;
}
