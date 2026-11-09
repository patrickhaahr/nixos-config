---
name: browser-qa
description: Browser QA of a running web app through the browse MCP tools.
disable-model-invocation: true
---

Run the QA in a subagent when the harness has one, so the long transcript stays out of the main context: hand it these steps and the target.

Test from the user's side with the browse MCP tools (`browser_*`). On a desktop they drive the user's logged-in Chromium; on a server, a headless one. Take a snapshot before each interaction. If the tools are missing or report the extension disconnected, stop and say so: reading the code is not QA.

1. Derive the expected behaviour from the request. Start the dev server if needed and note the URL.
2. Walk the happy path, then realistic failure and boundary paths: empty, invalid and long input, back and refresh, a narrow viewport.
3. For each defect capture the steps, expected vs actual, URL, a screenshot, and console or network errors.
4. Ask before any destructive, paid or externally visible action.
5. Close the tabs and stop the servers you started.

Report confirmed defects first by severity, then unverified concerns, then what you covered and what you could not.
