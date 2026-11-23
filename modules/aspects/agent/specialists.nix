{ self, ... }:
{
  flake.modules.homeManager.agent-specialists =
    { pkgs, ... }:
    {
      imports = [ self.modules.homeManager.pi-specialists ];

      pi.specialists = {
        media = {
          displayName = "Pi Media";
          domain = "Generated images, video, audio, speech, music and 3D through fal.";
          mcpServers.fal.url = "https://mcp.fal.ai/mcp-relay";
        };
        cloudflare = {
          displayName = "Pi Cloudflare";
          domain = "Cloudflare Workers, Pages, R2, D1, KV and account changes.";
          mcpServers.cloudflare-api.url = "https://mcp.cloudflare.com/mcp";
          packages = [ pkgs.wrangler ];
        };
        ui = {
          displayName = "Pi UI";
          domain = "Interface design, restyling, motion and design reviews.";
          mcpServers.inspo.url = "https://inspomcp.dev/api/mcp";
        };
        qa = {
          displayName = "Pi QA";
          domain = "Driving web and mobile apps live and writing end-to-end tests.";
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
