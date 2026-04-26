---
name: agent-browser
description: CLI tool for AI agents to browse the web, interact with UI elements, and analyze frontend applications. Supports navigation, clicking, typing, and capturing snapshots for accessibility analysis.
---

## Overview
`agent-browser` is a CLI tool designed for AI agents to interact with web pages. It allows you to navigate to URLs, inspect the accessibility tree (snapshot), interact with elements (click, type, fill), and extract information.

## Core Workflow
The typical workflow for analyzing and interacting with a page is:
1.  **Open** a URL: `agent-browser open <url>`
2.  **Snapshot** the page to get an accessibility tree with reference IDs (e.g., `@12`): `agent-browser snapshot`
    *   Use `--interactive` or `-i` to see only interactive elements.
3.  **Interact** or **Inspect** using the reference IDs from the snapshot.
    *   `agent-browser click @12`
    *   `agent-browser fill @15 "text"`
    *   `agent-browser get text @20`

## Capabilities & Commands

### Navigation
*   `agent-browser open <url>` - Navigate to a URL.
*   `agent-browser back` - Go back.
*   `agent-browser forward` - Go forward.
*   `agent-browser reload` - Reload the page.

### Inspection (The "Eyes")
*   `agent-browser snapshot` - Returns the accessibility tree. This is the primary way to "see" the page structure and get element references.
    *   Flags: `-i` (interactive only), `-c` (compact), `-d <depth>` (limit depth).
*   `agent-browser screenshot [path]` - Take a screenshot (defaults to `screenshot.png`).
*   `agent-browser get <what> [selector]` - Get details about an element.
    *   `what`: `text`, `html`, `value`, `attr <name>`, `title`, `url`.

### Interaction (The "Hands")
*   `agent-browser click <selector>` - Click an element.
*   `agent-browser type <selector> <text>` - Type text into an element.
*   `agent-browser fill <selector> <text>` - Clear and fill an input.
*   `agent-browser press <key>` - Press a key (e.g., `Enter`, `Tab`).
*   `agent-browser scroll <dir> [px]` - Scroll `up`, `down`, `left`, `right`.
*   `agent-browser wait <selector|ms>` - Wait for an element to appear or for a duration.

### Sessions
*   `agent-browser session list` - List active sessions.
*   Use `--session <name>` with commands to use a specific isolated session.

## Usage Examples

**1. Analyze a Landing Page**
```bash
# Open the page
agent-browser open https://example.com

# Get the layout structure (interactive elements only for cleaner view)
agent-browser snapshot -i

# (Agent analyzes the output, e.g., sees a "Sign Up" button at ref @5)
```

**2. Fill a Form**
```bash
# Assuming we are on the form page and have identified elements via snapshot
agent-browser fill @10 "user@example.com"
agent-browser fill @12 "securepassword"
agent-browser click @15  # Submit button
```

**3. Debugging/Verification**
```bash
# Check if an element is visible
agent-browser is visible @error-message

# Take a screenshot to verify UI state
agent-browser screenshot error_state.png
```
