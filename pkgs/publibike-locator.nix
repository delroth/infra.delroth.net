{ stdenv, lib, fetchFromGitHub, nodePackages }:

stdenv.mkDerivation rec {
  pname = "publibike-locator";
  version = "5f81573f7474c9ece039dd5882e2d6908154e762";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "publibike-locator";
    rev = version;
    sha256 = "06gj1dbv321wc2b9fkz7s10vdyv85y7k4sdlrdp13csmaqd6i62f";
  };

  nativeBuildInputs = [ nodePackages.typescript ];

  installPhase = ''
    mkdir $out
    cp index.html app.js $out
  '';

  meta = with lib; {
    description = "A simple JavaScript page to locate bikes at close-by publibike.ch stations in Switzerland";
    homepage = https://delroth.net/publibike/;
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ delroth ];
  };
}
