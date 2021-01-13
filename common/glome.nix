{ pkgs, secrets, ... }:

let
in {
  services.getty.loginProgram = "${pkgs.glome}/bin/glome-login";
  services.getty.loginOptions = "-l ${pkgs.shadow}/bin/login -k ${secrets.glome.service-public} -- \\u";
}
