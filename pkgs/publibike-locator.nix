{ stdenv, lib, fetchFromGitHub, nodePackages }:

stdenv.mkDerivation rec {
  pname = "publibike-locator";
  version = "bdae416960009f27351bfa709199e1afcbfa34ff";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "publibike-locator";
    rev = version;
    sha256 = "sha256-1XAPNYgeW2K+0o/OgeynF8NfIOC+pRop8hrCyIF6Wno=";
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
