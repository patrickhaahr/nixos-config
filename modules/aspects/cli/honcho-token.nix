{ ... }: {
  perSystem = { pkgs, ... }: {
    packages.honcho-admin-token = pkgs.writeShellApplication {
      name = "honcho-admin-token";
      runtimeInputs = [ pkgs.nodejs pkgs.sops ];
      text = ''
        set -euo pipefail

        usage() {
          cat <<'EOF'
Usage: honcho-admin-token [--openconcho-js]

Mint a self-hosted Honcho admin API token from secrets/zaza.yaml.

Options:
  --openconcho-js  Print a browser console snippet that configures OpenConcho.

The token is a HS256 JWT signed with the SOPS-managed honcho_auth_jwt_secret.
EOF
        }

        mode="token"
        case "''${1:-}" in
          "") ;;
          --openconcho-js) mode="openconcho-js" ;;
          -h|--help) usage; exit 0 ;;
          *) usage >&2; exit 2 ;;
        esac

        secret="$(sops --decrypt --extract '["honcho_auth_jwt_secret"]' secrets/zaza.yaml | tr -d '\n')"
        export HONCHO_AUTH_JWT_SECRET="$secret"
        export HONCHO_TOKEN_MODE="$mode"

        node <<'EOF'
const { createHmac } = require("node:crypto");

function base64urlJson(value) {
  return Buffer.from(JSON.stringify(value)).toString("base64url");
}

const header = base64urlJson({ alg: "HS256", typ: "JWT" });
const payload = base64urlJson({ t: "", ad: true });
const signingInput = header + "." + payload;
const signature = createHmac("sha256", process.env.HONCHO_AUTH_JWT_SECRET)
  .update(signingInput)
  .digest("base64url");
const token = signingInput + "." + signature;

if (process.env.HONCHO_TOKEN_MODE === "openconcho-js") {
  const store = {
    instances: [
      {
        id: "zaza-honcho",
        name: "Zaza Honcho",
        baseUrl: "https://honcho.zaza.haahr.me",
        token,
      },
    ],
    activeId: "zaza-honcho",
  };

  console.log("localStorage.setItem(\"openconcho:instances\", " + JSON.stringify(JSON.stringify(store)) + ");");
  console.log("location.reload();");
} else {
  console.log(token);
}
EOF
      '';
    };
  };
}
