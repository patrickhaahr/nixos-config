{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };

    vercel-agent-skills = {
      url = "github:vercel-labs/agent-skills";
      flake = false;
    };

    vercel-agent-browser = {
      url = "github:vercel-labs/agent-browser";
      flake = false;
    };

    frontend-slides = {
      url = "github:zarazhangrui/frontend-slides";
      flake = false;
    };

    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };

    sentry-skills = {
      url = "github:getsentry/skills";
      flake = false;
    };

    dotnet-skillz = {
      url = "github:davidfowl/dotnet-skillz";
      flake = false;
    };

    lumen = {
      url = "github:jnsahaj/lumen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    helium.url = "github:schembriaiden/helium-browser-nix-flake";
    helium.inputs.nixpkgs.follows = "nixpkgs";

    handy = {
      url = "github:cjpais/Handy";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
}
