{ inputs, lib, ... }: {
  imports = [
    inputs.home-manager.flakeModules.home-manager
    inputs.flake-parts.flakeModules.modules
    ./aspects/hacking/default.nix
  ];

  config = {
    perSystem = { system, ... }: {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          "replace"
        ];
      };
    };

    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
