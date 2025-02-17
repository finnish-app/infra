{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [ "8.8.8.8"
 ];
    defaultGateway = "157.230.48.1";
    defaultGateway6 = {
      address = "2604:a880:400:d1::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="157.230.52.132"; prefixLength=20; }
{ address="10.10.0.5"; prefixLength=16; }
        ];
        ipv6.addresses = [
          { address="2604:a880:400:d1:0:1:8f4:5001"; prefixLength=64; }
{ address="fe80::18b6:63ff:fe55:cb6c"; prefixLength=64; }
        ];
        ipv4.routes = [ { address = "157.230.48.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = "2604:a880:400:d1::1"; prefixLength = 128; } ];
      };
            eth1 = {
        ipv4.addresses = [
          { address="10.116.0.2"; prefixLength=20; }
        ];
        ipv6.addresses = [
          { address="fe80::4c9f:5fff:fe09:ce8c"; prefixLength=64; }
        ];
        };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="1a:b6:63:55:cb:6c", NAME="eth0"
    ATTR{address}=="4e:9f:5f:09:ce:8c", NAME="eth1"
  '';
}
