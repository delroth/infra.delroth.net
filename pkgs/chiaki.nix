{ lib, mkDerivation, fetchFromGitHub
, cmake, ffmpeg, libopus, qtbase, qtmultimedia, qtsvg, pkgconfig, protobuf
, python3Packages, SDL2 }:

mkDerivation rec {
  pname = "chiaki";
  version = "1.0.0";

  src = fetchFromGitHub {
    rev = "v${version}";
    owner = "thestr4ng3r";
    repo = "chiaki";
    fetchSubmodules = true;
    sha256 = "0xl4ig4sbpbwnszvjhnjqfd75g0vqa65vybnqi58xzdz4vjhj6rb";
  };

  nativeBuildInputs = [
    cmake pkgconfig protobuf python3Packages.python python3Packages.protobuf
  ];
  buildInputs = [ ffmpeg libopus qtbase qtmultimedia qtsvg protobuf SDL2 ];

  doCheck = true;
}
