{...}:

{
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  programs.mosh.enable = true;
}
