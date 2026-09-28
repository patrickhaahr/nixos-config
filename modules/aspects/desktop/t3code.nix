{
  flake.modules.nixos.t3code =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.t3code ];
    };
}
