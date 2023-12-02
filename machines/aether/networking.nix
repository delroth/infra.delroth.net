{config, ...}:

{
  # Rename interfaces to logical semantic names.
  systemd.network.links = {
    "10-upstream" = {
      matchConfig.MACAddress = "50:6b:4b:38:93:ea";
      linkConfig.Name = "upstream";
    };
    "10-down-25g" = {
      matchConfig.MACAddress = "50:6b:4b:38:93:eb";
      linkConfig.Name = "down-25g";
    };
    "10-down-10g-tl" = {
      matchConfig.MACAddress = "ee:31:06:c8:00:09";
      linkConfig.Name = "down-10g-tl";
    };
    "10-down-10g-tr" = {
      matchConfig.MACAddress = "ee:31:06:c8:00:07";
      linkConfig.Name = "down-10g-tr";
    };
    "10-down-10g-bl" = {
      matchConfig.MACAddress = "ee:31:06:c8:00:0a";
      linkConfig.Name = "down-10g-bl";
    };
    "10-down-10g-br" = {
      matchConfig.MACAddress = "ee:31:06:c8:00:08";
      linkConfig.Name = "down-10g-br";
    };
    "10-down-1g" = {
      matchConfig.MACAddress = "ee:31:06:c8:00:11";
      linkConfig.Name = "down-1g";
    };
  };

  networking.bridges.downstream.interfaces = [
    "down-25g"
    "down-10g-tl"
    "down-10g-tr"
    "down-10g-bl"
    "down-10g-br"
    "down-1g"
  ];

  systemd.network.wait-online.ignoredInterfaces = config.networking.bridges.downstream.interfaces ++ [
    "downstream"
  ];
}
