{
  gamingClient = import ./gaming-client.nix;
  infraDevMachine = import ./infra-dev-machine.nix;
  iotGateway = import ./iot-gateway.nix;
  ircClient = import ./irc-client.nix;
  matrixSynapse = import ./matrix-synapse.nix;
  nixBuilder = import ./nix-builder.nix;
  syncthingMirror = import ./syncthing-mirror.nix;
  syncthingRelay = import ./syncthing-relay.nix;
  torRelay = import ./tor-relay.nix;
  wireguardServer = import ./wireguard-server.nix;
}
