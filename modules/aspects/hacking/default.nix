{ self, ... }:
{
  flake.modules.nixos.hacking =
    { pkgs, ... }:
    {
      imports = [ self.modules.nixos.hacking-john ];

      boot.kernelModules = [ "wireguard" ];

      environment.systemPackages = with pkgs; [
        _7zz
        binwalk
        burpsuite
        clamav
        exiftool
        feroxbuster
        ffuf
        ghidra-bin
        hashcat
        nmap
        thc-hydra
        wireguard-tools
        wireshark
        yara
      ];
    };

  flake.modules.homeManager.hacking = {
    imports = with self.modules.homeManager; [
      hacking-burp-mcp
      hacking-john
      hacking-rockyou
    ];

    home.file."hacking/AGENTS.md".source = ./AGENTS.md;
  };
}
