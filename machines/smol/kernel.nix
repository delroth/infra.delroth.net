{ pkgs }:

let
  kernel = pkgs.callPackage ./pkgs/kernel.nix { };
  self = pkgs.linuxPackagesFor kernel;
in self // {
  al_eth = self.callPackage ./pkgs/al_eth.nix { };
  al_thermal = self.callPackage ./pkgs/al_thermal.nix { };
}
