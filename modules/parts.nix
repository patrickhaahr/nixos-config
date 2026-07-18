{ inputs, lib, ... }: {
  imports = [
    inputs.home-manager.flakeModules.home-manager
    inputs.flake-parts.flakeModules.modules
    ./aspects/hacking/default.nix
  ];

  config = {
    perSystem =
      { system, ... }:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfreePredicate =
            pkg:
            builtins.elem (lib.getName pkg) [
              "replace"
            ];
        };
      in
      {
        _module.args.pkgs = pkgs;
        formatter = pkgs.nixfmt-tree;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            just
            nixfmt
            nixfmt-tree
            statix
          ];
        };
      };

    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
