{ stdenv, lib, fetchFromGitHub, glib, libconfuse, meson, ninja, openssl, pkg-config }:

stdenv.mkDerivation {
  pname = "glome";
  version = "2020-08-05";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "glome";
    rev = "a523a19e37769240f86b1a655986f6f302f85d40";
    sha256 = "1wfhxq0xzsk4c9qlrl6y6hmyj15qrjl5w3v44xlsc9vv3rdgb17a";
  };

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ glib libconfuse openssl ];

  outputs = [ "out" "dev" ];
  postPatch = "patchShebangs .";

  doCheck = true;

  meta = with lib; {
    description = "A protocol providing secure authentication and authorization for low dependency environments";
    homepage = "https://github.com/google/glome";
    license = with licenses; [ asl2 ];
    maintainers = with maintainers; [ delroth ];
  };
}
