{ ... }:

{
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    startWhenNeeded = true;
  };
  programs.mosh.enable = true;
}
