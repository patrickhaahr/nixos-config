{ ... }: {
  flake.modules.homeManager."hacking-burp-mcp" =
    { pkgs, ... }:
    let
      burpMcpJar = pkgs.fetchurl {
        url = "https://github.com/PortSwigger/mcp-server/releases/download/v1.3.0/burp-mcp-all.jar";
        hash = "sha256-xAESRe59oMuQG5wENauj2EWKtbDiB44ah/0CXtk8eJI=";
      };
    in
    {
      home.file."hacking/burp/burp-mcp-all.jar".source = burpMcpJar;
    };
}
