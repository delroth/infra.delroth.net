{ pkgs }:

let
  # For some reason, does not boot with a hardened kernel.
  kernel = pkgs.linux_latest;
  self = pkgs.linuxPackagesFor kernel;
in self // {
  intel_nuc_led = self.callPackage ./pkgs/intel_nuc_led.nix { };
}
