{lib, ...}: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [
      "8.8.8.8"
    ];
    defaultGateway = "159.223.96.1";
    defaultGateway6 = {
      address = "2604:a880:400:d1::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          {
            address = "159.223.105.163";
            prefixLength = 20;
          }
          {
            address = "10.10.0.5";
            prefixLength = 16;
          }
        ];
        ipv6.addresses = [
          {
            address = "2604:a880:400:d1::106d:f001";
            prefixLength = 64;
          }
          {
            address = "fe80::981c:c4ff:fe8d:77d9";
            prefixLength = 64;
          }
        ];
        ipv4.routes = [
          {
            address = "159.223.96.1";
            prefixLength = 32;
          }
        ];
        ipv6.routes = [
          {
            address = "2604:a880:400:d1::1";
            prefixLength = 128;
          }
        ];
      };
      eth1 = {
        ipv4.addresses = [
          {
            address = "10.116.0.2";
            prefixLength = 20;
          }
        ];
        ipv6.addresses = [
          {
            address = "fe80::f4d8:f7ff:fea2:6f73";
            prefixLength = 64;
          }
        ];
      };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="9a:1c:c4:8d:77:d9", NAME="eth0"
    ATTR{address}=="f6:d8:f7:a2:6f:73", NAME="eth1"
  '';
}
