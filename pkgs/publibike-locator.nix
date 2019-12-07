{ stdenv, lib, fetchFromGitHub, nodePackages }:

stdenv.mkDerivation rec {
  pname = "publibike-locator";
  version = "9229a2e48b4e218a4723b6aaef8781d87eca2fa8";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "publibike-locator";
    rev = version;
    sha256 = "07lrjzhhjlz731xr41ccq443jq5rf2b27fzfnm34mq1wa4q4r3gz";
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
