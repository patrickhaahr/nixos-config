# Custom MCP installation

## Scope and discovery

1. Identify the intended consumer and configuration owner before delegating installation. Pass the exact endpoint, chosen server name, authentication requirement and target profile in the brief. From a specialist, target root explicitly with `hermes -p default` rather than relying on inherited defaults.
2. Read current authoritative Hermes MCP documentation and inspect the supported installation interface. Use the connection-management tool for catalog entries. If it reports that a custom URL is outside the catalog, inspect `hermes mcp add --help` for the supported custom-server path instead of guessing a catalog name or hand-editing generated configuration.
3. For a server confirmed to require no authentication, use discovery-first CLI installation with `--url` and omit authentication settings. Interactive discovery may still ask whether authentication is required and which tools to enable. Answer those prompts explicitly; do not interpret discovery followed by EOF cancellation as an installation.

## Persistence gate

4. Treat discovered tools and persisted configuration as separate outcomes. After installation, read back the exact target through `hermes -p default mcp list` and `hermes -p default mcp test <name>`. A CLI can print a save-success line after a persistence refusal; the readback is authoritative.
5. If Home Manager refuses persistence, do not retry flags or patch the generated YAML. Inspect the declarative source and report that deployment is required. Obtain authorization for the configuration change and switch before applying them. Carry that authorization into the specialist brief, with the exact deployment command Patrick approved.
6. Before promising a declarative switch, have the specialist inspect whether activation would restart the gateway hosting the task. Identify this execution-boundary issue before spending time on verification or announcing deployment. Authorization to switch does not make an in-gateway restart safe. If an external execution context is required, report that specific dependency early; do not claim deployment is running when only verification is running.
7. During declarative deployment, preserve concurrent repository changes and existing MCP entries. Require repository verification, deployment output, and readback of the generated target configuration. Do not call an edited source file an installed server. Do not commit or push merely because a switch was authorized.

## Functional and session gates

8. Require one actual harmless read-tool invocation after configuration discovery succeeds. Report discovery count separately from successful tool execution; a list of descriptions is not a functional test.
9. Verify fresh CLI access and existing chat access separately. Use the documented profile-scoped `/reload-mcp` in the existing chat when necessary. Do not restart the gateway from its own child command. If the active session has not been refreshed, state that limitation rather than claiming its tools are already available.
