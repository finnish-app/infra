{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [ "8.8.8.8"
 ];
    defaultGateway = "164.92.80.1";
    defaultGateway6 = {
      address = "2604:a880:4:1d0::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="164.92.87.138"; prefixLength=20; }
{ address="10.48.0.5"; prefixLength=16; }
        ];
        ipv6.addresses = [
          { address="2604:a880:4:1d0::26a8:d000"; prefixLength=64; }
{ address="fe80::f4a4:f0ff:fe78:e7b"; prefixLength=64; }
        ];
        ipv4.routes = [ { address = "164.92.80.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = "2604:a880:4:1d0::1"; prefixLength = 128; } ];
      };
            eth1 = {
        ipv4.addresses = [
          { address="10.124.0.2"; prefixLength=20; }
        ];
        ipv6.addresses = [
          { address="fe80::a073:71ff:fe6f:485f"; prefixLength=64; }
        ];
        };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="f6:a4:f0:78:0e:7b", NAME="eth0"
    ATTR{address}=="a2:73:71:6f:48:5f", NAME="eth1"
  '';
}
