{
  stdenv,
  lib,
  fetchFromGitHub,
  python3Packages,
}:

stdenv.mkDerivation rec {
  pname = "repology-notifier";
  version = "716ec7ab48c25f95947d203403601e3dab1e2b0a";

  src = fetchFromGitHub {
    owner = "delroth";
    repo = "repology-outdated-notify";
    rev = version;
    sha256 = "1nlki3ic8dw0bs24wvx9gzrim5ybh5hdml7qnb5bwz29gqv46473";
  };

  nativeBuildInputs = [ python3Packages.wrapPython ];
  propagatedBuildInputs = [ python3Packages.python ];

  pythonPath = with python3Packages; [
    feedparser
    requests
  ];

  postPatch = "patchShebangs .";

  installPhase = ''
    mkdir -p $out/bin
    cp repology-outdated-notify.py $out/bin
    chmod +x $out/bin/repology-outdated-notify.py
  '';

  fixupPhase = "wrapPythonPrograms";

  meta = with lib; {
    description = "Notifies of outdated maintained packages on Repology";
    homepage = "https://github.com/delroth/repology-outdated-notify";
    license = licenses.mit;
    maintainers = with maintainers; [ delroth ];
  };
}
