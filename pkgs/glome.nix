{ stdenv, lib, fetchFromGitHub, glib, libconfuse, meson, ninja, openssl, pkg-config }:

stdenv.mkDerivation {
  pname = "glome";
  version = "2021-01-07";

  src = fetchFromGitHub {
    owner = "google";
    repo = "glome";
    rev = "40cc757b3235f0a01f6c785982647efadee07a34";
    sha256 = "1pb89dakhzm82q12rkcqga51f0szczbxz58l7kf5vmh61dyyj5w2";
  };

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ glib libconfuse openssl ];

  outputs = [ "out" "dev" ];
  postPatch = "patchShebangs .";

  doCheck = true;

  meta = with lib; {
    description = "A protocol providing secure authentication and authorization for low dependency environments";
    homepage = "https://github.com/google/glome";
    license = with licenses; [ asl20 ];
    maintainers = with maintainers; [ delroth ];
  };
}
