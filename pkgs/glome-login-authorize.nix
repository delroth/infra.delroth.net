{ stdenv, lib, fetchFromGitHub, makeWrapper, python3, python3Packages }:

stdenv.mkDerivation rec {
  pname = "glome-login-authorize";
  version = "427e105e42532356053874d0b938ffcbd621c048";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "glome-login-authorize";
    rev = version;
    sha256 = "1l37ri25kn8bm76ydzm16lirkxjnhc1i6j50dsbnnfv1yaab826f";
  };

  nativeBuildInputs = [ makeWrapper ];
  pythonDeps = with python3Packages; [ cryptography pyglome ];

  installPhase = ''
    install -Dm644 glome-login-authorize.py -t $out/libexec
    makeWrapper ${python3.interpreter} $out/bin/glome-login-authorize \
        --argv0 glome-login-authorize \
        --add-flags $out/libexec/glome-login-authorize.py \
        --prefix PYTHONPATH : "${python3Packages.makePythonPath pythonDeps}"
  '';

  meta = with lib; {
    description = "A simple Python script using pyglome to generate glome-login authorization tokens.";
    homepage = "https://github.com/delroth/glome-login-authorize";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ delroth ];
  };
}
