with import <nixpkgs> {};

buildGoPackage rec {
  name = "nginx-sso-${version}";
  version = "0.12.0";
  rev = "v${version}";

  goPackagePath = "github.com/Luzifer/nginx-sso";

  src = fetchFromGitHub {
    inherit rev;
    owner = "Luzifer";
    repo = "nginx-sso";
    sha256 = "09hcizwrhlk0wqypyaf1vxwnz9l7ax5bsz04cj8lsfcgfr76has6";
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
