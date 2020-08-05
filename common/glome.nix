{ pkgs, secrets, ... }:

let
in {
  services.mingetty.loginProgram = "${pkgs.glome}/bin/glome-login";
  services.mingetty.loginOptions = "-l ${pkgs.shadow}/bin/login -k ${secrets.glome.service-public} -- \\u";
}
