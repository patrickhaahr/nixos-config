---
name: dump-dom
description: Use `helium-browser --dump-dom` to inspect the fully rendered DOM after JavaScript execution. For debugging layout/scrolling issues and scraping dynamic pages.
---

## Overview
Get the actual browser-rendered DOM after JS runs. Unlike static HTML, this shows hydrated content, dynamic elements, and runtime changes.

## Usage
```bash
helium-browser --headless --no-sandbox --disable-gpu --virtual-time-budget=8000 --dump-dom <url>
```

## When to Use
- Debug layout/scrolling issues by inspecting the real rendered tree
- Verify if an element exists in the browser but not in source HTML
- Scrape dynamic pages that `curl` cannot capture
- Compare JSX assumptions vs actual rendered output

## Why It Helps
If a `div` won't scroll, seeing the real DOM (nesting, styles, attributes) is faster than tracing through JSX components.

## Tips
- Increase `--virtual-time-budget` if DOM is incomplete
- Pair with screenshots for visual confirmation
