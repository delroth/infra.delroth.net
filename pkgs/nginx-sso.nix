with import <nixpkgs> {};

buildGoPackage rec {
  name = "nginx-sso-${version}";
  version = "0.11.0";
  rev = "v${version}";

  goPackagePath = "github.com/Luzifer/nginx-sso";

  src = fetchFromGitHub {
    inherit rev;
    owner = "Luzifer";
    repo = "nginx-sso";
    sha256 = "00l4jglsd3qhdk7gkr7982bglmcmiwxm1nxmcqzc0igd7vmp39vw";
  };

  postInstall = ''
    mkdir -p $bin/share
    cp -R $src/frontend $bin/share
  '';

  meta = with stdenv.lib; {
    description = "SSO authentication provider for the auth_request nginx module";
    homepage = https://github.com/Luzifer/nginx-sso;
    license = licenses.asl20;
    maintainers = with maintainers; [ delroth ];
    platforms = platforms.unix;
  };
}
