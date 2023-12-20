{ secrets, ... }:

{
  security.glome-login.enable = true;
  security.glome-login.publicKey = secrets.glome.service-public;
}
