{ stdenv, lib, fetchFromGitHub, nodePackages }:

stdenv.mkDerivation rec {
  pname = "publibike-locator";
  version = "cf06774fc37f191791dcc83a3599df5a353d43af";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "publibike-locator";
    rev = version;
    sha256 = "sha256-1pX0Gt8doVspHXLoomFweTrq/0H9LKWITUJL2fWTGK8=";
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
