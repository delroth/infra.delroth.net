{ stdenv, lib, fetchFromGitHub, nodePackages }:

stdenv.mkDerivation rec {
  pname = "publibike-locator";
  version = "9e1ca1310609d99dffe6f1ad36c2bc81f62daffc";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "publibike-locator";
    rev = version;
    sha256 = "sha256-1j0szA5U8xwJebvPKnTq/B0RUSJRvwoHa3VRhNlPoSw=";
  };

  nativeBuildInputs = [ nodePackages.typescript ];

  installPhase = ''
    mkdir $out
    cp index.html app.js manifest.json worker.js favicon.svg $out
  '';

  meta = with lib; {
    description = "A simple JavaScript page to locate bikes at close-by publibike.ch stations in Switzerland";
    homepage = https://delroth.net/publibike/;
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ delroth ];
  };
}
