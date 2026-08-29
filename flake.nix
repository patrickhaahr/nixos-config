{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };

    kitlangton-skills = {
      url = "github:kitlangton/skills";
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

    diagram-design = {
      url = "github:cathrynlavery/diagram-design";
      flake = false;
    };

    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };

    better-auth-skills = {
      url = "github:better-auth/skills";
      flake = false;
    };

    cloudflare-skills = {
      url = "github:cloudflare/skills";
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

    claude-skill-typst = {
      url = "github:lucifer1004/claude-skill-typst";
      flake = false;
    };

    rhys-sullivan-skills = {
      url = "github:RhysSullivan/skills";
      flake = false;
    };

    dmmulroy-coding-standards = {
      url = "git+https://gist.github.com/dmmulroy/9c80f1f499b031aa0b6525b5d9ae25f0.git";
      flake = false;
    };

    anti-slop = {
      url = "github:dmmulroy/anti-slop";
      flake = false;
    };

    cursor-plugins = {
      url = "github:cursor/plugins";
      flake = false;
    };

    wshobson-agents = {
      url = "github:wshobson/agents";
      flake = false;
    };

    jakubkrehel-skills = {
      url = "github:jakubkrehel/skills";
      flake = false;
    };

    marketing-skills = {
      url = "github:coreyhaines31/marketingskills";
      flake = false;
    };

    lumen = {
      url = "github:jnsahaj/lumen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:herdrdev/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hunk = {
      url = "github:modem-dev/hunk";
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

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs = {
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
        nixpkgs.follows = "nixpkgs";
      };
    };

    hermes-agent.url = "github:NousResearch/hermes-agent/v2026.8.19";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
