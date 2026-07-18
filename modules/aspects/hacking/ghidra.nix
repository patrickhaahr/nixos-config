_: {
  flake.modules.nixos."hacking-ghidra" = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.ghidra-bin ];
  };
}
