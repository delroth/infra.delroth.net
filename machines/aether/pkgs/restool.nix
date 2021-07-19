{ stdenv, lib, fetchgit, bash, coreutils, dtc, file, gawk, gnugrep, gnused }:

stdenv.mkDerivation rec {
  pname = "restool";
  version = "LSDK-20.04";

  src = fetchgit {
    url = "https://source.codeaurora.org/external/qoriq/qoriq-components/restool";
    rev = version;
    sha256 = "1agkcqjfgi51h7jwxa6lr4czdj09jbf14hjpji4r5i73x0dxvl85";
  };

  nativeBuildInputs = [ file ];
  buildInputs = [ bash coreutils dtc gawk gnugrep gnused ];

  postPatch = ''
    sed -i /-Werror/d Makefile
  '';

  makeFlags = [
    "prefix=$(out)"
    "VERSION=${version}"
  ];

  preFixup = ''
    # wrapProgram interacts badly with the ls-main tool, which relies on the
    # shell's $0 argument to figure out which operation to run (busybox-style
    # symlinks). Instead, inject the environment directly into the shell
    # scripts we need to wrap.
    for tool in ls-append-dpl ls-debug ls-main; do
      sed -i "1 a export PATH=\"$out/bin:${lib.makeBinPath buildInputs}:\$PATH\"" $out/bin/$tool
    done
  '';

  meta = with lib; {
    description = "DPAA2 Resource Management Tool";
    homepage = "https://source.codeaurora.org/external/qoriq/qoriq-components/restool/about/";
    license = licenses.bsd3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ delroth ];
  };
}
