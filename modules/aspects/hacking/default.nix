{ self, ... }: {
  flake.modules.nixos.hacking = {
    imports = [
      self.modules.nixos."hacking-binwalk"
      self.modules.nixos."hacking-burpsuite"
      self.modules.nixos."hacking-exiftool"
      self.modules.nixos."hacking-ffuf"
      self.modules.nixos."hacking-feroxbuster"
      self.modules.nixos."hacking-hashcat"
      self.modules.nixos."hacking-hydra"
      self.modules.nixos."hacking-john"
      self.modules.nixos."hacking-nmap"
      self.modules.nixos."hacking-wireguard"
      self.modules.nixos."hacking-wireshark"
    ];
  };

  flake.modules.homeManager.hacking = {
    imports = [
      self.modules.homeManager."hacking-guide"
      self.modules.homeManager."hacking-john"
      self.modules.homeManager."hacking-rockyou"
    ];
  };
}
