# Common libraries for *.delroth.net. Passed to NixOS modules as "my".
{
  common = import ./common;
  secrets = import ./secrets;
}
