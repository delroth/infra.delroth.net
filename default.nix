# Common libraries for *.delroth.net. Passed to NixOS modules as "my".
{
  common = import ./common;
  roles = import ./roles;
  secrets = import ./secrets;
}
