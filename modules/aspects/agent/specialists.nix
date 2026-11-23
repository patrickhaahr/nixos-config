{ self, ... }:
{
  flake.modules.homeManager.agent-specialists =
    { pkgs, ... }:
    {
      imports = [ self.modules.homeManager.pi-specialists ];

      pi.specialists = {
        media = {
          displayName = "Pi Media";
          mcpServers.fal.url = "https://mcp.fal.ai/mcp-relay";
        };
        cloudflare = {
          displayName = "Pi Cloudflare";
          mcpServers.cloudflare-api.url = "https://mcp.cloudflare.com/mcp";
          packages = [ pkgs.wrangler ];
        };
        ui = {
          displayName = "Pi UI";
          mcpServers.inspo.url = "https://inspomcp.dev/api/mcp";
        };
        qa = {
          displayName = "Pi QA";
          mcpServers.e2e = {
            command = "${pkgs.nodejs_22}/bin/npx";
            args = [
              "-y"
              "e2e@0.24.0"
              "mcp"
            ];
          };
          packages = [ pkgs.nodejs_22 ];
        };
      };
    };
}
