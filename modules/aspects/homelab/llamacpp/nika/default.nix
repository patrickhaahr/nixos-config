{ self, ... }: {
  flake.modules.nixos.homelab-llamacpp-nika =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      toolSchemaProxy = pkgs.writeText "llamacpp-tool-schema-proxy.js" ''
        const http = require("http");

        const listenPort = 8081;
        const target = new URL("http://127.0.0.1:8080");

        const asType = (type) => {
          if (Array.isArray(type)) {
            return type.find((item) => item !== "null") ?? "string";
          }

          return typeof type === "string" ? type : undefined;
        };

        const normalizeSchema = (schema) => {
          if (!schema || typeof schema !== "object" || Array.isArray(schema)) {
            return { type: "string" };
          }

          const union = schema.anyOf ?? schema.oneOf ?? schema.allOf;
          if (Array.isArray(union)) {
            return normalizeSchema(union.find((item) => asType(item?.type) !== "null") ?? union[0]);
          }

          const type = asType(schema.type) ?? (schema.properties ? "object" : schema.items ? "array" : "string");
          const normalized = { type };

          if (typeof schema.description === "string") {
            normalized.description = schema.description;
          }

          if (Array.isArray(schema.enum) && schema.enum.every((item) => ["string", "number", "boolean"].includes(typeof item))) {
            normalized.enum = schema.enum;
          }

          if (type === "object") {
            const properties = {};
            for (const [name, propertySchema] of Object.entries(schema.properties ?? {})) {
              properties[name] = normalizeSchema(propertySchema);
            }

            normalized.properties = properties;
            normalized.required = Array.isArray(schema.required)
              ? schema.required.filter((name) => Object.hasOwn(properties, name))
              : [];
            normalized.additionalProperties = false;
          }

          if (type === "array") {
            normalized.items = normalizeSchema(schema.items);
          }

          return normalized;
        };

        http.createServer((req, res) => {
          const chunks = [];
          req.on("data", (chunk) => chunks.push(chunk));
          req.on("end", () => {
            let body = Buffer.concat(chunks);

            if (req.method === "POST" && req.url.includes("/chat/completions")) {
              try {
                const json = JSON.parse(body.toString());
                let tools = 0;

                delete json.grammar;
                if (json.response_format?.type === "json_schema") {
                  delete json.response_format;
                }

                for (const tool of json.tools ?? []) {
                  if (tool?.type === "function" && tool.function?.parameters) {
                    tool.function.parameters = normalizeSchema(tool.function.parameters);
                    tools += 1;
                  }
                }

                if (tools) {
                  console.log(`[llamacpp-tool-schema-proxy] normalized schemas for ''${tools} tools`);
                }

                body = Buffer.from(JSON.stringify(json));
                req.headers["content-length"] = String(body.length);
              } catch (_error) {
                // Non-JSON requests are forwarded unchanged.
              }
            }

            const proxyReq = http.request({
              hostname: target.hostname,
              port: target.port,
              path: req.url,
              method: req.method,
              headers: {
                ...req.headers,
                host: target.host,
              },
            }, (proxyRes) => {
              res.writeHead(proxyRes.statusCode, proxyRes.headers);
              proxyRes.pipe(res);
            });

            proxyReq.on("error", (error) => {
              if (!res.headersSent) {
                res.writeHead(502, { "content-type": "application/json" });
              }
              res.end(JSON.stringify({ error: error.message }));
            });

            proxyReq.write(body);
            proxyReq.end();
          });
        }).listen(listenPort, "127.0.0.1");
      '';
    in
    {
      imports = [
        self.modules.nixos.homelab-llamacpp-nika-qwen3-14b
        self.modules.nixos.homelab-llamacpp-nika-qwen3-6-35b-a3b
      ];

      options.services.llamacpp.nika.model = lib.mkOption {
        type = lib.types.enum [
          "none"
          "qwen3-14b"
          "qwen3-6-35b-a3b"
        ];
        default = "qwen3-14b";
        description = "The llama.cpp model service to run on nika.";
      };

      config.systemd.services.llamacpp-tool-schema-proxy =
        lib.mkIf (config.services.llamacpp.nika.model != "none")
          {
            description = "llama.cpp OpenCode tool schema compatibility proxy";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
              ExecStart = "${pkgs.nodejs}/bin/node ${toolSchemaProxy}";
              Restart = "on-failure";
              RestartSec = "2s";
              DynamicUser = true;
              NoNewPrivileges = true;
              PrivateTmp = true;
            };
          };
    };
}
