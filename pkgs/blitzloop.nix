{ lib, fetchFromGitHub, python3Packages, freetype, libjack2, mpv }:

let
  freetype-py = python3Packages.buildPythonPackage rec {
    pname = "freetype-py";
    version = "2.1.0.post1";
    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "76383bb3e59efa6ce0be1797ed70207d7d1e421611df3aceb269673c4a77c2cc";
    };

    buildInputs = with python3Packages; [ setuptools-scm ];
    propagatedBuildInputs = [ freetype ];
    checkInputs = with python3Packages; [ pytest ];

    postPatch = ''
      # https://github.com/NixOS/nixpkgs/issues/7307
      substituteInPlace freetype/raw.py \
          --replace "ctypes.util.find_library('freetype')" \
                    "'${freetype}/lib/libfreetype.so'"
    '';

    checkPhase = "cd tests && pytest";

    meta = with lib; {
      description = "Python binding for the freetype library";
      homepage = https://github.com/rougier/freetype-py;
      license = licenses.bsd3;
      maintainers = with maintainers; [ delroth ];
    };
  };

  jaconv = python3Packages.buildPythonPackage rec {
    pname = "jaconv";
    version = "0.2.4";
    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "2ccdf768da20d55f30e8801e5e2e27783aae1bb29b890e503e1124134d6d09c9";
    };

    checkInputs = with python3Packages; [ nose ];

    meta = with lib; {
      description = "Pure-Python Japanese character interconverter for Hiragana, Katakana, Hankaku and Zenkaku";
      homepage = https://github.com/ikegami-yukino/jaconv;
      license = licenses.mit;
      maintainers = with maintainers; [ delroth ];
    };
  };

  pympv = python3Packages.buildPythonPackage rec {
    pname = "pympv";
    version = "0.6.0";
    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "e364ecc21bc9d438d2902d989767a2d00d70958466154dd9c6a1e395f0ea67b0";
    };

    buildInputs = [ mpv ] ++ (with python3Packages; [ cython ]);

    # No upstream tests.
    doCheck = false;

    meta = with lib; {
      description = "A python wrapper for libmpv";
      homepage = https://github.com/marcan/pympv;
      license = licenses.gpl3;
      maintainers = with maintainers; [ delroth ];
    };
  };
in

python3Packages.buildPythonApplication rec {
  pname = "blitzloop";
  version = "unstable-2019-04-15";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "blitzloop";
    rev = "08408b36cb0da584c9cdb8f1979c3b8ed77e26ec";
    sha256 = "0rprg3847p05k2fbpfi308xzjmk7ql2dzhlbv38kc1a52c5hpg7r";
  };

  buildInputs = [
    libjack2
  ] ++ (with python3Packages; [
    cython
  ]);

  propagatedBuildInputs = with python3Packages; [
    bottle
    configargparse
    freetype-py
    jaconv
    pympv
    numpy
    paste
    pillow
    pyopengl
  ];

  # No upstream tests.
  doCheck = false;

  meta = with lib; {
    description = "Open source karaoke software";
    longDescription = ''
      Blitzloop is a karaoke software written to replicate the karaoke
      experience you might get in Japan. Screen is dedicated to displaying
      video and lyrics, while control is provided remotely (via browser).
      Please note that watered down alcohol drinks are not included.
    '';
    homepage = https://github.com/marcan/blitzloop;
    license = with licenses; [ gpl2 gpl3 ];
    maintainers = with maintainers; [ delroth ];
  };
}
