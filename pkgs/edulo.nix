{ stdenv, lib, fetchurl, dpkg, makeWrapper, electron }:

stdenv.mkDerivation (finalAttrs: {
  pname = "edulo";
  version = "2024-05-05";

  src = fetchurl {
    url = "https://management.edulo.com/edulo_amd64.deb";
    hash = "sha256-Ef0melwVEzUiEGR6efcKJYBC0buPjqTO5XgkEVi/5/4=";
  };

  nativeBuildInputs = [ dpkg makeWrapper ];

  unpackCmd = ''
    mkdir -p root
    dpkg -x $curSrc root
  '';

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp -r usr/lib/edulo/{resources,locales} $out/
    makeWrapper ${lib.getBin electron}/bin/electron $out/bin/edulo --add-flags $out/resources/app
  '';
})
